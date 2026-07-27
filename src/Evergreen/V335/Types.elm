module Evergreen.V335.Types exposing (..)

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
import Evergreen.V335.AiChat
import Evergreen.V335.Audio
import Evergreen.V335.Call
import Evergreen.V335.ChannelDescription
import Evergreen.V335.ChannelName
import Evergreen.V335.Cloudflare
import Evergreen.V335.Coord
import Evergreen.V335.CssPixels
import Evergreen.V335.CustomEmoji
import Evergreen.V335.Discord
import Evergreen.V335.DiscordAttachmentId
import Evergreen.V335.DiscordUserData
import Evergreen.V335.DmChannel
import Evergreen.V335.DmChannelId
import Evergreen.V335.Drawing
import Evergreen.V335.Editable
import Evergreen.V335.EmailAddress
import Evergreen.V335.Embed
import Evergreen.V335.Emoji
import Evergreen.V335.FileStatus
import Evergreen.V335.Game
import Evergreen.V335.Go
import Evergreen.V335.GuildName
import Evergreen.V335.Id
import Evergreen.V335.ImageEditor
import Evergreen.V335.ImageViewer
import Evergreen.V335.LinkedAndOtherDiscordUsers
import Evergreen.V335.Local
import Evergreen.V335.LocalState
import Evergreen.V335.Log
import Evergreen.V335.LoginForm
import Evergreen.V335.MembersAndOwner
import Evergreen.V335.Message
import Evergreen.V335.MessageInput
import Evergreen.V335.MessageView
import Evergreen.V335.MyUi
import Evergreen.V335.NonemptyDict
import Evergreen.V335.NonemptySet
import Evergreen.V335.OneOrGreater
import Evergreen.V335.OneToOne
import Evergreen.V335.Pages.Admin
import Evergreen.V335.Pagination
import Evergreen.V335.PersonName
import Evergreen.V335.Ports
import Evergreen.V335.Postmark
import Evergreen.V335.Range
import Evergreen.V335.RichText
import Evergreen.V335.Route
import Evergreen.V335.Scroll
import Evergreen.V335.SecretId
import Evergreen.V335.SessionIdHash
import Evergreen.V335.Slack
import Evergreen.V335.Sticker
import Evergreen.V335.TextEditor
import Evergreen.V335.ToBackendLog
import Evergreen.V335.Touch
import Evergreen.V335.TwoFactorAuthentication
import Evergreen.V335.Ui.Anim
import Evergreen.V335.Untrusted
import Evergreen.V335.User
import Evergreen.V335.UserAgent
import Evergreen.V335.UserSession
import Evergreen.V335.WordSpellingGame
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
    { name : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , pressedSubmit : Bool
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
    | LoginFormMsg Evergreen.V335.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V335.Pages.Admin.Msg
    | PressedLogOut Evergreen.V335.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V335.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V335.Route.Route
    | SelectedFilesToAttach ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) EditGuildForm
    | PressedResetEditGuildChanges (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | PressedSubmitEditGuildChanges (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V335.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V335.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V335.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V335.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V335.NonemptyDict.NonemptyDict Int Evergreen.V335.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V335.NonemptyDict.NonemptyDict Int Evergreen.V335.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRoute Evergreen.V335.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V335.NonemptySet.NonemptySet (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V335.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V335.AiChat.Msg
    | GameMsg Evergreen.V335.Game.Msg
    | GoSpectatorMsg Evergreen.V335.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V335.Editable.Msg Evergreen.V335.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V335.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
        { fileId : Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
        { fileId : Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V335.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V335.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V335.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V335.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.User.NotificationLevel
    | GotStartupData Evergreen.V335.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V335.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId
        , otherUserId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result () Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRoute Evergreen.V335.MessageInput.Msg
    | MessageInputMsg Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRoute Evergreen.V335.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V335.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V335.Range.Range, Evergreen.V335.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V335.Range.Range, Evergreen.V335.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V335.Call.FromJs)
    | VoiceChatMsg Evergreen.V335.Call.Msg
    | PressedChannelHeaderTab Evergreen.V335.UserSession.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V335.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V335.Audio.LoadError Evergreen.V335.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch
    | TypedChannelSearch String
    | PressedClearChannelSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V335.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V335.UserSession.UserSession
    , currentlyViewing : Evergreen.V335.UserSession.Viewing
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.LocalState.DiscordFrontendGuild
    , user : Evergreen.V335.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.User.FrontendUser
    , discordUsers : Evergreen.V335.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V335.SessionIdHash.SessionIdHash Evergreen.V335.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V335.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId) Evergreen.V335.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V335.Call.CallId (Evergreen.V335.NonemptyDict.NonemptyDict ( Evergreen.V335.Id.Id Evergreen.V335.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V335.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V335.Go.PublicGoMatchData Evergreen.V335.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V335.Route.Route
    , windowSize : Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V335.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V335.Audio.LoadError Evergreen.V335.Audio.Source
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V335.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V335.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V335.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V335.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V335.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.ChannelName.ChannelName Evergreen.V335.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.ChannelName.ChannelName Evergreen.V335.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | Local_EditGuildName (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.GuildName.GuildName
    | Local_DeleteGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V335.GuildName.GuildName (Evergreen.V335.UserSession.ToBeFilledInByBackend (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V335.Id.DiscordGuildOrDmId_DmData (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V335.UserSession.SetViewing
    | Local_SetName Evergreen.V335.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V335.Id.GuildOrDmId (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V335.Id.GuildOrDmId (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V335.Id.DiscordGuildOrDmId (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ChannelMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V335.Id.DiscordGuildOrDmId (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.Message.Message Evergreen.V335.Id.ThreadMessageId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V335.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V335.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V335.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V335.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V335.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V335.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V335.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V335.NonemptySet.NonemptySet (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V335.Call.LocalChange
    | Local_Game Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Game.LocalChange
    | Local_Drawing Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Drawing.AnchorType Evergreen.V335.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Effect.Time.Posix Evergreen.V335.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))) Evergreen.V335.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V335.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId))) Evergreen.V335.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.ChannelName.ChannelName Evergreen.V335.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.ChannelName.ChannelName Evergreen.V335.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | Server_EditGuildName (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.GuildName.GuildName
    | Server_DeleteGuild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V335.LocalState.JoinGuildError
            { guildId : Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId
            , guild : Evergreen.V335.LocalState.FrontendGuild
            , owner : Evergreen.V335.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))) (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V335.Id.DiscordGuildOrDmId_DmData (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Maybe Evergreen.V335.FileStatus.FileHash)
    | Server_SetGuildIcon (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Maybe Evergreen.V335.FileStatus.FileHash)
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V335.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V335.SessionIdHash.SessionIdHash Evergreen.V335.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V335.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V335.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId Evergreen.V335.UserSession.Viewing
    | Server_ClientDisconnected Evergreen.V335.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V335.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.ChannelName.ChannelName (Evergreen.V335.Discord.OptionalData (Maybe String)) (List Evergreen.V335.Discord.Overwrite)
    | Server_DiscordDmChannelCreated
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
        (Evergreen.V335.NonemptyDict.NonemptyDict
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Maybe (Evergreen.V335.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V335.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V335.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V335.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V335.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V335.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V335.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.OptionalData String) (Evergreen.V335.Discord.OptionalData (Maybe String)) (List Evergreen.V335.Discord.Overwrite)
    | Server_DiscordUpdateRole (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId) Evergreen.V335.LocalState.DiscordRole
    | Server_UpdateDiscordMembers
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
        (Evergreen.V335.MembersAndOwner.MembersAndOwner
            (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            , roles : SeqSet.SeqSet (Evergreen.V335.Discord.Id Evergreen.V335.Discord.RoleId)
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId) Evergreen.V335.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V335.Call.ServerChange
    | Server_Game (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Game.LocalChange
    | Server_Drawing (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Drawing.AnchorType Evergreen.V335.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V335.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V335.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V335.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V335.Id.AnyGuildOrDmId Evergreen.V335.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V335.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels) (Maybe Evergreen.V335.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId) (Evergreen.V335.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V335.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V335.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V335.Local.Local LocalMsg Evergreen.V335.LocalState.LocalState
    , admin : Evergreen.V335.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId, Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V335.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V335.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V335.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V335.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V335.Id.AnyGuildOrDmId, Evergreen.V335.Id.ThreadRoute ) (Evergreen.V335.NonemptyDict.NonemptyDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V335.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V335.Scroll.ScrollPosition
    , textEditor : Evergreen.V335.TextEditor.Model
    , profilePictureEditor : Evergreen.V335.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId, Evergreen.V335.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V335.Emoji.Model
    , voiceChat : Evergreen.V335.Call.Model
    , games : SeqDict.SeqDict Evergreen.V335.Id.GuildOrDmId Evergreen.V335.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V335.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    , friendsSearch : String
    , channelSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    , typedTextCounter : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V335.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V335.Range.Range
                , direction : Evergreen.V335.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V335.NonemptyDict.NonemptyDict Int Evergreen.V335.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V335.NonemptyDict.NonemptyDict Int Evergreen.V335.Touch.Touch
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
    | AdminToFrontend Evergreen.V335.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V335.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V335.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V335.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V335.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V335.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V335.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V335.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V335.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V335.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V335.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V335.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V335.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V335.Audio.LoadError Evergreen.V335.Audio.Source
    , startupData : Evergreen.V335.Ports.StartupData
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V335.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V335.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V335.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V335.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V335.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId, Evergreen.V335.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V335.DmChannelId.DmChannelId, Evergreen.V335.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId, Evergreen.V335.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId, Evergreen.V335.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V335.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V335.NonemptyDict.NonemptyDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V335.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V335.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V335.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V335.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) Evergreen.V335.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) Evergreen.V335.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V335.DmChannelId.DmChannelId Evergreen.V335.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) Evergreen.V335.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Slack.Id Evergreen.V335.Slack.ChannelId) Evergreen.V335.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V335.OneToOne.OneToOne String (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    , slackUsers : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Slack.Id Evergreen.V335.Slack.UserId) (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
    , slackServers : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Slack.Id Evergreen.V335.Slack.TeamId) (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId)
    , slackToken : Maybe Evergreen.V335.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V335.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V335.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V335.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V335.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V335.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V335.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V335.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V335.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Evergreen.V335.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId, Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V335.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V335.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V335.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V335.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.LocalState.LoadingDiscordChannel (List Evergreen.V335.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V335.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId) Evergreen.V335.Sticker.StickerData
    , discordStickers : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.Discord.Id Evergreen.V335.Discord.StickerId) (Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId) Evergreen.V335.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V335.OneToOne.OneToOne Evergreen.V335.RichText.DiscordCustomEmojiIdAndName (Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V335.Postmark.ApiKey
    , serverSecret : Evergreen.V335.SecretId.SecretId Evergreen.V335.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V335.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V335.OneToOne.OneToOne (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.GamePublicId) ( Evergreen.V335.DmChannelId.GuildOrFullDmId, Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V335.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V335.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V335.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRoute (Maybe Evergreen.V335.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_Dm Evergreen.V335.DmChannelId.DmChannelId Evergreen.V335.Id.ThreadRoute (Maybe Evergreen.V335.UserSession.ChannelHeaderTab)
    | InitialLoadRequested_DiscordGuild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRoute
    | InitialLoadRequested_DiscordDm (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)
    | InitialLoadRequested_Admin (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V335.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V335.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V335.Untrusted.Untrusted Evergreen.V335.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V335.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V335.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V335.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V335.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V335.PersonName.PersonName Evergreen.V335.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V335.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V335.Slack.OAuthCode Evergreen.V335.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V335.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V335.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V335.EmailAddress.EmailAddress (Result Evergreen.V335.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V335.EmailAddress.EmailAddress (Result Evergreen.V335.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V335.EmailAddress.EmailAddress (Result Evergreen.V335.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V335.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMaybeMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Result Evergreen.V335.Discord.HttpError Evergreen.V335.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V335.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Result Evergreen.V335.Discord.HttpError Evergreen.V335.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Result Evergreen.V335.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Result Evergreen.V335.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Result Evergreen.V335.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) (Result Evergreen.V335.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji (Result Evergreen.V335.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji (Result Evergreen.V335.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji (Result Evergreen.V335.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.MessageId) Evergreen.V335.Emoji.EmojiOrCustomEmoji (Result Evergreen.V335.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V335.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V335.Discord.HttpError (List ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId, Maybe Evergreen.V335.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Effect.Time.Posix Evergreen.V335.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V335.Slack.CurrentUser
            , team : Evergreen.V335.Slack.Team
            , users : List Evergreen.V335.Slack.User
            , channels : List ( Evergreen.V335.Slack.Channel, List Evergreen.V335.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Result Effect.Http.Error Evergreen.V335.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V335.Local.ChangeId Effect.Time.Posix Evergreen.V335.Call.CallId Evergreen.V335.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V335.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V335.Local.ChangeId Effect.Time.Posix Evergreen.V335.Call.CallId Evergreen.V335.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V335.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V335.Local.ChangeId Evergreen.V335.Call.ConnectionId Evergreen.V335.Cloudflare.RealtimeSessionId (List Evergreen.V335.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V335.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V335.Local.ChangeId Evergreen.V335.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) Evergreen.V335.Discord.UserAuth (Result Evergreen.V335.Discord.HttpError Evergreen.V335.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Result Evergreen.V335.Discord.HttpError Evergreen.V335.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
        (Result
            Evergreen.V335.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId
                , members : List (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
                }
            , List
                ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId
                , { guild : Evergreen.V335.Discord.GatewayGuild
                  , channels : List Evergreen.V335.Discord.Channel
                  , icon : Maybe Evergreen.V335.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Bool Evergreen.V335.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V335.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.AttachmentId, Evergreen.V335.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V335.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V335.Discord.Id Evergreen.V335.Discord.AttachmentId, Evergreen.V335.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V335.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V335.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V335.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V335.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) (Result Evergreen.V335.Discord.HttpError (List Evergreen.V335.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Result Evergreen.V335.Discord.HttpError (List Evergreen.V335.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V335.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V335.DmChannelId.DmChannelId Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V335.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) Evergreen.V335.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V335.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId) (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V335.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId)
        (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V335.Discord.HttpError
            { guild : Evergreen.V335.Discord.GatewayGuild
            , channels : List Evergreen.V335.Discord.Channel
            , icon : Maybe Evergreen.V335.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Result Evergreen.V335.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V335.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (List ( Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId, Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V335.Id.Id Evergreen.V335.Id.StickerId, Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V335.Id.Id Evergreen.V335.Id.UserId) (List ( Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V335.Id.Id Evergreen.V335.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V335.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V335.Discord.HttpError (List Evergreen.V335.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V335.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V335.SecretId.SecretId Evergreen.V335.SecretId.ServerSecret))
    | ReloadedDiscordGuildForAdmin Effect.Time.Posix Evergreen.V335.Local.ChangeId Effect.Lamdera.ClientId (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) (Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId) (Result Evergreen.V335.Discord.HttpError ( Evergreen.V335.Discord.Guild, List Evergreen.V335.Discord.Channel2 ))
    | GotTimeForWebsocketListenClose (Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V335.FileStatus.FileHash Int (Maybe (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
