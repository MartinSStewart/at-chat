module Evergreen.V323.Types exposing (..)

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
import Evergreen.V323.AiChat
import Evergreen.V323.Audio
import Evergreen.V323.Call
import Evergreen.V323.ChannelDescription
import Evergreen.V323.ChannelName
import Evergreen.V323.Cloudflare
import Evergreen.V323.Coord
import Evergreen.V323.CssPixels
import Evergreen.V323.CustomEmoji
import Evergreen.V323.Discord
import Evergreen.V323.DiscordAttachmentId
import Evergreen.V323.DiscordUserData
import Evergreen.V323.DmChannel
import Evergreen.V323.DmChannelId
import Evergreen.V323.Drawing
import Evergreen.V323.Editable
import Evergreen.V323.EmailAddress
import Evergreen.V323.Embed
import Evergreen.V323.Emoji
import Evergreen.V323.FileStatus
import Evergreen.V323.Game
import Evergreen.V323.Go
import Evergreen.V323.GuildName
import Evergreen.V323.Id
import Evergreen.V323.ImageEditor
import Evergreen.V323.ImageViewer
import Evergreen.V323.LinkedAndOtherDiscordUsers
import Evergreen.V323.Local
import Evergreen.V323.LocalState
import Evergreen.V323.Log
import Evergreen.V323.LoginForm
import Evergreen.V323.MembersAndOwner
import Evergreen.V323.Message
import Evergreen.V323.MessageInput
import Evergreen.V323.MessageView
import Evergreen.V323.MyUi
import Evergreen.V323.NonemptyDict
import Evergreen.V323.NonemptySet
import Evergreen.V323.OneOrGreater
import Evergreen.V323.OneToOne
import Evergreen.V323.Pages.Admin
import Evergreen.V323.Pagination
import Evergreen.V323.PersonName
import Evergreen.V323.Ports
import Evergreen.V323.Postmark
import Evergreen.V323.Range
import Evergreen.V323.RichText
import Evergreen.V323.Route
import Evergreen.V323.Scroll
import Evergreen.V323.SecretId
import Evergreen.V323.SessionIdHash
import Evergreen.V323.Slack
import Evergreen.V323.Sticker
import Evergreen.V323.TextEditor
import Evergreen.V323.ToBackendLog
import Evergreen.V323.Touch
import Evergreen.V323.TwoFactorAuthentication
import Evergreen.V323.Ui.Anim
import Evergreen.V323.Untrusted
import Evergreen.V323.User
import Evergreen.V323.UserAgent
import Evergreen.V323.UserSession
import Evergreen.V323.WordSpellingGame
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
    | LoginFormMsg Evergreen.V323.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V323.Pages.Admin.Msg
    | PressedLogOut Evergreen.V323.SessionIdHash.SessionIdHash
    | ElmUiMsg Evergreen.V323.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V323.Route.Route
    | SelectedFilesToAttach ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | PressedDeleteInviteLink (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | PressedToggleInviteLinkQrCode (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCopyImage String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V323.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown
        { ctrlKey : Bool
        , metaKey : Bool
        , shiftKey : Bool
        , key : String
        }
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V323.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V323.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V323.Ports.NotificationPermission
    | TouchStart Duration.Duration (Evergreen.V323.NonemptyDict.NonemptyDict Int Evergreen.V323.Touch.Touch)
    | TouchMoved Duration.Duration (Evergreen.V323.NonemptyDict.NonemptyDict Int Evergreen.V323.Touch.Touch)
    | TouchEnd Duration.Duration
    | TouchCancel Duration.Duration
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRoute Evergreen.V323.Scroll.ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V323.NonemptySet.NonemptySet (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Bool (Maybe String) (Maybe String)
    | PressedShowUserOption
    | PressedCloseUserOptions
    | PressedExpandContainer UserOptionSection
    | TwoFactorMsg Evergreen.V323.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V323.AiChat.Msg
    | GameMsg Evergreen.V323.Game.Msg
    | GoSpectatorMsg Evergreen.V323.Go.SpectatorMsg
    | UserNameEditableMsg (Evergreen.V323.Editable.Msg Evergreen.V323.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V323.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
        { fileId : Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
        { fileId : Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.MessageView.MessageViewMsg
    | ImageViewerMsg Evergreen.V323.ImageViewer.Msg
    | GotRegisterPushSubscription Evergreen.V323.Ports.RegisterPushSubscription
    | SelectedNotificationMode Evergreen.V323.UserSession.NotificationMode
    | SelectedEmailNotifications Evergreen.V323.User.EmailNotifications
    | PressedGuildNotificationLevel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.User.NotificationLevel
    | GotStartupData Evergreen.V323.Ports.StartupData
    | PressedCloseImageInfo
    | PressedMemberListBack
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V323.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedReloadDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId
        , otherUserId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber Bool (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRoute Evergreen.V323.MessageInput.Msg
    | MessageInputMsg Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRoute Evergreen.V323.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V323.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V323.Range.Range, Evergreen.V323.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V323.Range.Range, Evergreen.V323.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V323.Call.FromJs)
    | VoiceChatMsg Evergreen.V323.Call.Msg
    | PressedChannelHeaderTab Evergreen.V323.Route.ChannelHeaderTab
    | FileDragEnter Duration.Duration
    | FileDragLeave
    | FileDropped (List Effect.File.File)
    | PressedUnregisterServiceWorkers
    | PressedLoadDebugData
    | GotServiceWorkerData String
    | DrawingMsg Evergreen.V323.Drawing.Msg
    | LoadedPopSound (Result Evergreen.V323.Audio.LoadError Evergreen.V323.Audio.Source)
    | TypedFriendsSearch String
    | PressedClearFriendsSearch


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V323.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V323.UserSession.UserSession
    , currentlyViewing : Maybe ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.LocalState.DiscordFrontendGuild
    , user : Evergreen.V323.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.User.FrontendUser
    , discordUsers : Evergreen.V323.LinkedAndOtherDiscordUsers.LinkedAndOtherDiscordUsers
    , otherSessions : SeqDict.SeqDict Evergreen.V323.SessionIdHash.SessionIdHash Evergreen.V323.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V323.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId) Evergreen.V323.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V323.Call.CallId (Evergreen.V323.NonemptyDict.NonemptyDict ( Evergreen.V323.Id.Id Evergreen.V323.Id.UserId, Effect.Lamdera.ClientId ) Evergreen.V323.Call.RemoteCallData)
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type PublicGoMatch
    = PublicGoMatch_NotLoaded
    | PublicGoMatch_Loading
    | PublicGoMatch_Loaded Evergreen.V323.Go.PublicGoMatchData Evergreen.V323.Go.GameModel
    | PublicGoMatch_Missing


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V323.Route.Route
    , windowSize : Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , timezone : Effect.Time.Zone
    , startupData : Maybe Evergreen.V323.Ports.StartupData
    , publicGoMatch : PublicGoMatch
    , popSound : Result Evergreen.V323.Audio.LoadError Evergreen.V323.Audio.Source
    , lastUrlChange : Maybe Effect.Time.Posix
    , routingLog :
        List
            { time : Effect.Time.Posix
            , entry : String
            }
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V323.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V323.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V323.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V323.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V323.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.ChannelName.ChannelName Evergreen.V323.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.ChannelName.ChannelName Evergreen.V323.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId))
    | Local_DeleteInviteLink (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | Local_NewGuild Effect.Time.Posix Evergreen.V323.GuildName.GuildName (Evergreen.V323.UserSession.ToBeFilledInByBackend (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V323.Id.DiscordGuildOrDmId_DmData (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V323.UserSession.SetViewing
    | Local_SetName Evergreen.V323.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V323.Id.GuildOrDmId (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V323.Id.GuildOrDmId (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V323.Id.DiscordGuildOrDmId (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ChannelMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V323.Id.DiscordGuildOrDmId (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.Message.Message Evergreen.V323.Id.ThreadMessageId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V323.UserSession.NotificationMode
    | Local_SetEmailNotifications Evergreen.V323.User.EmailNotifications
    | Local_RegisterPushSubscription Effect.Time.Posix Evergreen.V323.Ports.RegisterPushSubscription
    | Local_TextEditor Evergreen.V323.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V323.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V323.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V323.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V323.NonemptySet.NonemptySet (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V323.Call.LocalChange
    | Local_Game Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Game.LocalChange
    | Local_Drawing Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Drawing.AnchorType Evergreen.V323.Drawing.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Effect.Time.Posix Evergreen.V323.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))) Evergreen.V323.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V323.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId))) Evergreen.V323.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.ChannelName.ChannelName Evergreen.V323.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.ChannelName.ChannelName Evergreen.V323.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | Server_DeleteInviteLink (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V323.LocalState.JoinGuildError
            { guildId : Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId
            , guild : Evergreen.V323.LocalState.FrontendGuild
            , owner : Evergreen.V323.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))) (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V323.Id.DiscordGuildOrDmId_DmData (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.User.NotificationLevel
    | Server_PushNotificationFailed Evergreen.V323.Ports.SubscribeData Effect.Http.Error
    | Server_NewSession Evergreen.V323.SessionIdHash.SessionIdHash Evergreen.V323.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V323.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V323.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId (Maybe ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ))
    | Server_ClientDisconnected Evergreen.V323.SessionIdHash.SessionIdHash Effect.Lamdera.ClientId
    | Server_TextEditor Evergreen.V323.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.LinkedAndOtherDiscordUsers.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.ChannelName.ChannelName (Evergreen.V323.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)
        (Evergreen.V323.NonemptyDict.NonemptyDict
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.UserSession.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Maybe (Evergreen.V323.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V323.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V323.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V323.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V323.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V323.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V323.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (Evergreen.V323.Discord.OptionalData String) (Evergreen.V323.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
        (Evergreen.V323.MembersAndOwner.MembersAndOwner
            (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId) Evergreen.V323.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V323.Call.ServerChange
    | Server_Game (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Game.LocalChange
    | Server_Drawing (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Drawing.AnchorType Evergreen.V323.Drawing.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) LocalChange
    | ServerChange ServerChange


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V323.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V323.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V323.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    , imageUrl : Maybe String
    , linkUrl : Maybe String
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V323.Id.AnyGuildOrDmId Evergreen.V323.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V323.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels) (Maybe Evergreen.V323.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId) (Evergreen.V323.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V323.Editable.Model
    , domainWhitelistInput : String
    , debugData :
        Maybe
            { data : String
            , loadedAt : Effect.Time.Posix
            }
    }


type FileDrag
    = NoFileDrag (Maybe Effect.Time.Posix)
    | FileDragging Effect.Time.Posix Evergreen.V323.OneOrGreater.OneOrGreater


type alias LoggedIn2 =
    { localState : Evergreen.V323.Local.Local LocalMsg Evergreen.V323.LocalState.LocalState
    , admin : Evergreen.V323.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId, Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V323.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V323.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V323.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V323.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V323.Id.AnyGuildOrDmId, Evergreen.V323.Id.ThreadRoute ) (Evergreen.V323.NonemptyDict.NonemptyDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V323.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : Evergreen.V323.Scroll.ScrollPosition
    , textEditor : Evergreen.V323.TextEditor.Model
    , profilePictureEditor : Evergreen.V323.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId, Evergreen.V323.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V323.Emoji.Model
    , voiceChat : Evergreen.V323.Call.Model
    , games : SeqDict.SeqDict Evergreen.V323.Id.GuildOrDmId Evergreen.V323.Game.Model
    , fileDragOverCount : FileDrag
    , drawingMode : Evergreen.V323.Drawing.Model
    , showInviteLinkQrCode : Maybe (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    , friendsSearch : String
    , expandedUserOptions : SeqSet.SeqSet UserOptionSection
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V323.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V323.Range.Range
                , direction : Evergreen.V323.Range.SelectionDirection
                }
        }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V323.NonemptyDict.NonemptyDict Int Evergreen.V323.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V323.NonemptyDict.NonemptyDict Int Evergreen.V323.Touch.Touch
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
    | AdminToFrontend Evergreen.V323.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V323.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V323.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V323.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V323.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V323.ImageEditor.ToFrontend
    | GetPublicGoMatchResponse (Result () Evergreen.V323.Go.PublicGoMatchResponse)


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V323.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V323.Ui.Anim.State
    , lastCopied : Maybe Evergreen.V323.MyUi.LastCopy
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V323.AiChat.FrontendModel
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V323.Emoji.CachedEmojiData
    , publicGoMatch : PublicGoMatch
    , imageViewer : Maybe Evergreen.V323.ImageViewer.Model
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    , popSound : Result Evergreen.V323.Audio.LoadError Evergreen.V323.Audio.Source
    , startupData : Evergreen.V323.Ports.StartupData
    , lastUrlChange : Maybe Effect.Time.Posix
    , routingLog :
        List
            { time : Effect.Time.Posix
            , entry : String
            }
    }


type FrontendModel_
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias FrontendModel =
    Evergreen.V323.Audio.Model FrontendMsg_ FrontendModel_


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V323.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V323.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V323.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V323.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId, Evergreen.V323.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V323.DmChannelId.DmChannelId, Evergreen.V323.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId, Evergreen.V323.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId, Evergreen.V323.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V323.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V323.NonemptyDict.NonemptyDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V323.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V323.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V323.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V323.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) Evergreen.V323.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) Evergreen.V323.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V323.DmChannelId.DmChannelId Evergreen.V323.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) Evergreen.V323.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Slack.Id Evergreen.V323.Slack.ChannelId) Evergreen.V323.DmChannelId.DmChannelId
    , slackWorkspaces : Evergreen.V323.OneToOne.OneToOne String (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    , slackUsers : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Slack.Id Evergreen.V323.Slack.UserId) (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
    , slackServers : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Slack.Id Evergreen.V323.Slack.TeamId) (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId)
    , slackToken : Maybe Evergreen.V323.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V323.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V323.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V323.Slack.ClientSecret
    , openRouterKey : Maybe String
    , cloudflareRealtimeApiToken : Maybe Evergreen.V323.Cloudflare.RealtimeApiToken
    , cloudflareRealtimeAppId : Maybe Evergreen.V323.Cloudflare.AppId
    , cloudflareAccountId : Maybe Evergreen.V323.Cloudflare.AccountId
    , cloudflareAnalyticsApiToken : Maybe Evergreen.V323.Cloudflare.AnalyticsApiToken
    , textEditor : Evergreen.V323.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Evergreen.V323.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId, Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V323.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V323.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V323.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V323.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.LocalState.LoadingDiscordChannel (List Evergreen.V323.Discord.Message))
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V323.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId) Evergreen.V323.Sticker.StickerData
    , discordStickers : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.Discord.Id Evergreen.V323.Discord.StickerId) (Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId) Evergreen.V323.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V323.OneToOne.OneToOne Evergreen.V323.RichText.DiscordCustomEmojiIdAndName (Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V323.Postmark.ApiKey
    , serverSecret : Evergreen.V323.SecretId.SecretId Evergreen.V323.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    , websocketCloseEvents : Array.Array Evergreen.V323.LocalState.WebsocketClosedEvent
    , goMatchPublicIds : Evergreen.V323.OneToOne.OneToOne (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.GamePublicId) ( Evergreen.V323.DmChannelId.GuildOrFullDmId, Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId )
    , wordSpellingGameEnglish : Evergreen.V323.WordSpellingGame.WordList
    , wordSpellingGameSwedish : Evergreen.V323.WordSpellingGame.WordList
    }


type alias FrontendMsg =
    Evergreen.V323.Audio.Msg FrontendMsg_


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V323.DmChannelId.DmChannelId Evergreen.V323.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V323.Id.DiscordGuildOrDmId Evergreen.V323.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V323.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V323.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V323.Untrusted.Untrusted Evergreen.V323.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V323.Pages.Admin.ToBackend
    | LogOutRequest Evergreen.V323.SessionIdHash.SessionIdHash
    | LocalModelChangeRequest Evergreen.V323.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V323.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V323.PersonName.PersonName Evergreen.V323.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V323.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V323.Slack.OAuthCode Evergreen.V323.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V323.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V323.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Pagination.PageId))
    | GetPublicGoMatchRequest (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.GamePublicId)


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V323.EmailAddress.EmailAddress (Result Evergreen.V323.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V323.EmailAddress.EmailAddress (Result Evergreen.V323.Postmark.SendEmailError ())
    | SentNotificationEmail Effect.Time.Posix Evergreen.V323.EmailAddress.EmailAddress (Result Evergreen.V323.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Result ( Effect.Websocket.CloseEventCode, String ) String)
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V323.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMaybeMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Result Evergreen.V323.Discord.HttpError Evergreen.V323.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V323.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Result Evergreen.V323.Discord.HttpError Evergreen.V323.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Result Evergreen.V323.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Result Evergreen.V323.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Result Evergreen.V323.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) (Result Evergreen.V323.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji (Result Evergreen.V323.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji (Result Evergreen.V323.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji (Result Evergreen.V323.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.MessageId) Evergreen.V323.Emoji.EmojiOrCustomEmoji (Result Evergreen.V323.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V323.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V323.Discord.HttpError (List ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId, Maybe Evergreen.V323.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Effect.Time.Posix Evergreen.V323.Ports.SubscribeData (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V323.Slack.CurrentUser
            , team : Evergreen.V323.Slack.Team
            , users : List Evergreen.V323.Slack.User
            , channels : List ( Evergreen.V323.Slack.Channel, List Evergreen.V323.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Result Effect.Http.Error Evergreen.V323.Slack.TokenResponse)
    | GotCloudflareSessionCreated Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V323.Local.ChangeId Effect.Time.Posix Evergreen.V323.Call.CallId Evergreen.V323.Cloudflare.Sdp (List String) (Result Effect.Http.Error Evergreen.V323.Cloudflare.RealtimeSessionId)
    | GotCloudflareSession Effect.Lamdera.SessionId Effect.Lamdera.ClientId Evergreen.V323.Local.ChangeId Effect.Time.Posix Evergreen.V323.Call.CallId Evergreen.V323.Cloudflare.RealtimeSessionId (Result Effect.Http.Error Evergreen.V323.Cloudflare.PushTracksResult)
    | GotCloudflarePullOffer Effect.Time.Posix Effect.Lamdera.ClientId Evergreen.V323.Local.ChangeId Evergreen.V323.Call.ConnectionId Evergreen.V323.Cloudflare.RealtimeSessionId (List Evergreen.V323.Cloudflare.TrackName) (Result Effect.Http.Error Evergreen.V323.Cloudflare.PullTracksResult)
    | GotCloudflareRenegotiateAck Effect.Lamdera.ClientId Evergreen.V323.Local.ChangeId Evergreen.V323.Cloudflare.Sdp (Result Effect.Http.Error ())
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) Evergreen.V323.Discord.UserAuth (Result Evergreen.V323.Discord.HttpError Evergreen.V323.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Result Evergreen.V323.Discord.HttpError Evergreen.V323.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
        (Result
            Evergreen.V323.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId
                , members : List (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
                }
            , List
                ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId
                , { guild : Evergreen.V323.Discord.GatewayGuild
                  , channels : List Evergreen.V323.Discord.Channel
                  , icon : Maybe Evergreen.V323.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Bool Evergreen.V323.LocalState.WebsocketClosedEvent
    | WebsocketSentDataForUser (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V323.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.AttachmentId, Evergreen.V323.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V323.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V323.Discord.Id Evergreen.V323.Discord.AttachmentId, Evergreen.V323.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V323.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V323.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V323.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V323.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) (Result Evergreen.V323.Discord.HttpError (List Evergreen.V323.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Result Evergreen.V323.Discord.HttpError (List Evergreen.V323.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V323.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V323.DmChannelId.DmChannelId Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V323.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) Evergreen.V323.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V323.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId) (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V323.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId)
        (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V323.Discord.HttpError
            { guild : Evergreen.V323.Discord.GatewayGuild
            , channels : List Evergreen.V323.Discord.Channel
            , icon : Maybe Evergreen.V323.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId) (Result Evergreen.V323.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V323.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (List ( Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId, Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V323.Id.Id Evergreen.V323.Id.StickerId, Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V323.Id.Id Evergreen.V323.Id.UserId) (List ( Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V323.Id.Id Evergreen.V323.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V323.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V323.Discord.HttpError (List Evergreen.V323.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V323.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V323.SecretId.SecretId Evergreen.V323.SecretId.ServerSecret))
    | GotTimeForWebsocketListenClose (Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId) Effect.Websocket.CloseEventCode String Effect.Time.Posix
    | GotCloudflareUsage Effect.Time.Posix (Result Effect.Http.Error Int)
    | GotCloudflareEgressForAdmin Effect.Lamdera.ClientId (Result Effect.Http.Error Int)
    | GotRustServerFileUpload Evergreen.V323.FileStatus.FileHash Int (Maybe (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels))
    | GotEnglishWordList (Result Effect.Http.Error String)
    | GotSwedishWordList (Result Effect.Http.Error String)
