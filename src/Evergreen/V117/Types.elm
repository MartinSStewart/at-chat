module Evergreen.V117.Types exposing (..)

import Array
import Browser
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V117.AiChat
import Evergreen.V117.ChannelName
import Evergreen.V117.Coord
import Evergreen.V117.CssPixels
import Evergreen.V117.Discord
import Evergreen.V117.Discord.Id
import Evergreen.V117.DmChannel
import Evergreen.V117.Editable
import Evergreen.V117.EmailAddress
import Evergreen.V117.Emoji
import Evergreen.V117.FileStatus
import Evergreen.V117.GuildName
import Evergreen.V117.Id
import Evergreen.V117.ImageEditor
import Evergreen.V117.Local
import Evergreen.V117.LocalState
import Evergreen.V117.Log
import Evergreen.V117.LoginForm
import Evergreen.V117.Message
import Evergreen.V117.MessageInput
import Evergreen.V117.MessageView
import Evergreen.V117.NonemptyDict
import Evergreen.V117.NonemptySet
import Evergreen.V117.OneToOne
import Evergreen.V117.Pages.Admin
import Evergreen.V117.PersonName
import Evergreen.V117.Ports
import Evergreen.V117.Postmark
import Evergreen.V117.RichText
import Evergreen.V117.Route
import Evergreen.V117.SecretId
import Evergreen.V117.SessionIdHash
import Evergreen.V117.Slack
import Evergreen.V117.TextEditor
import Evergreen.V117.Touch
import Evergreen.V117.TwoFactorAuthentication
import Evergreen.V117.Ui.Anim
import Evergreen.V117.User
import Evergreen.V117.UserAgent
import Evergreen.V117.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V117.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V117.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) Evergreen.V117.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) Evergreen.V117.LocalState.DiscordFrontendGuild
    , user : Evergreen.V117.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V117.SessionIdHash.SessionIdHash Evergreen.V117.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V117.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V117.Route.Route
    , windowSize : Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V117.Ports.NotificationPermission
    , pwaStatus : Evergreen.V117.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V117.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V117.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V117.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))) Evergreen.V117.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V117.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))) Evergreen.V117.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) Evergreen.V117.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.UserSession.ToBeFilledInByBackend (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V117.GuildName.GuildName (Evergreen.V117.UserSession.ToBeFilledInByBackend (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V117.Id.GuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))) (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V117.Id.DiscordGuildOrDmId_DmData (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V117.UserSession.SetViewing
    | Local_SetName Evergreen.V117.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V117.Id.GuildOrDmId (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V117.Id.GuildOrDmId (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V117.Id.DiscordGuildOrDmId (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V117.Id.DiscordGuildOrDmId (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.Message.Message Evergreen.V117.Id.ThreadMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V117.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V117.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V117.TextEditor.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Effect.Time.Posix Evergreen.V117.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))) Evergreen.V117.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V117.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))) Evergreen.V117.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) Evergreen.V117.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V117.LocalState.JoinGuildError
            { guildId : Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId
            , guild : Evergreen.V117.LocalState.FrontendGuild
            , owner : Evergreen.V117.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Id.GuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Id.GuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Id.GuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))) (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V117.Id.DiscordGuildOrDmId_DmData (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.FileStatus.FileHash
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))) (Maybe (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V117.SessionIdHash.SessionIdHash Evergreen.V117.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V117.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V117.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V117.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.User.DiscordFrontendCurrentUser
    | Server_DiscordChannelCreated (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.NonemptySet.NonemptySet (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)


type LocalMsg
    = LocalChange (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , pressedSubmit : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) Evergreen.V117.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V117.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V117.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V117.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId) (Evergreen.V117.NonemptySet.NonemptySet Int))
    }


type ChannelSidebarMode
    = ChannelSidebarClosed
    | ChannelSidebarOpened
    | ChannelSidebarClosing
        { offset : Float
        }
    | ChannelSidebarOpening
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }


type LinkDiscordSubmitStatus
    = LinkDiscordNotSubmitted
        { attemptCount : Int
        }
    | LinkDiscordSubmitting
    | LinkDiscordSubmitted
    | LinkDiscordSubmitError Evergreen.V117.Discord.HttpError


type alias UserOptionsModel =
    { name : Evergreen.V117.Editable.Model
    , slackClientSecret : Evergreen.V117.Editable.Model
    , publicVapidKey : Evergreen.V117.Editable.Model
    , privateVapidKey : Evergreen.V117.Editable.Model
    , openRouterKey : Evergreen.V117.Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V117.Local.Local LocalMsg Evergreen.V117.LocalState.LocalState
    , admin : Maybe Evergreen.V117.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId, Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V117.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V117.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.NonemptyDict.NonemptyDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V117.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V117.TextEditor.Model
    , profilePictureEditor : Evergreen.V117.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V117.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V117.NonemptyDict.NonemptyDict Int Evergreen.V117.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V117.NonemptyDict.NonemptyDict Int Evergreen.V117.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V117.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V117.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V117.Ports.NotificationPermission
    , pwaStatus : Evergreen.V117.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V117.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V117.UserAgent.UserAgent
    , pageHasFocus : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V117.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V117.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V117.Discord.PartialUser
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V117.Discord.UserAuth
    , user : Evergreen.V117.Discord.User
    , connection : Evergreen.V117.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V117.Discord.User
    , linkedTo : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias BackendModel =
    { users : Evergreen.V117.NonemptyDict.NonemptyDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V117.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V117.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V117.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) Evergreen.V117.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V117.DmChannel.DmChannelId Evergreen.V117.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) Evergreen.V117.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Slack.Id Evergreen.V117.Slack.ChannelId) Evergreen.V117.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V117.OneToOne.OneToOne String (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    , slackUsers : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Slack.Id Evergreen.V117.Slack.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
    , slackServers : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Slack.Id Evergreen.V117.Slack.TeamId) (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    , slackToken : Maybe Evergreen.V117.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V117.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V117.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V117.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V117.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId, Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V117.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V117.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V117.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V117.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V117.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V117.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V117.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) Evergreen.V117.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) Evergreen.V117.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V117.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V117.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V117.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V117.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V117.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V117.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V117.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V117.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V117.NonemptyDict.NonemptyDict Int Evergreen.V117.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V117.NonemptyDict.NonemptyDict Int Evergreen.V117.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V117.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V117.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V117.Editable.Msg Evergreen.V117.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V117.Editable.Msg (Maybe Evergreen.V117.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V117.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V117.Editable.Msg Evergreen.V117.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V117.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V117.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V117.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V117.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ) (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V117.Id.AnyGuildOrDmId Evergreen.V117.Id.ThreadRouteWithMessage Evergreen.V117.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V117.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V117.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V117.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V117.TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
        , otherUserId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V117.Discord.UserAuth
    , user : Evergreen.V117.Discord.User
    , linkedTo : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V117.Discord.User
    , linkedTo : Evergreen.V117.Id.Id Evergreen.V117.Id.UserId
    , icon : Maybe Evergreen.V117.FileStatus.FileHash
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId
    , guild : Evergreen.V117.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )) Int Evergreen.V117.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )) Int Evergreen.V117.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V117.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V117.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V117.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V117.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute )) Evergreen.V117.PersonName.PersonName Evergreen.V117.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V117.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V117.Id.AnyGuildOrDmId, Evergreen.V117.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V117.Slack.OAuthCode Evergreen.V117.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V117.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V117.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V117.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V117.EmailAddress.EmailAddress (Result Evergreen.V117.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V117.EmailAddress.EmailAddress (Result Evergreen.V117.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Evergreen.V117.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V117.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Result Evergreen.V117.Discord.HttpError Evergreen.V117.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V117.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V117.RichText.RichText (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.FileStatus.FileId) Evergreen.V117.FileStatus.FileData) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Result Evergreen.V117.Discord.HttpError Evergreen.V117.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Result Evergreen.V117.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Result Evergreen.V117.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Result Evergreen.V117.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Result Evergreen.V117.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji (Result Evergreen.V117.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji (Result Evergreen.V117.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) Evergreen.V117.Id.ThreadRouteWithMessage (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji (Result Evergreen.V117.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) Evergreen.V117.Emoji.Emoji (Result Evergreen.V117.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | CreatedDiscordPrivateChannel Effect.Time.Posix (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Result Evergreen.V117.Discord.HttpError Evergreen.V117.Discord.Channel)
    | AiChatBackendMsg Evergreen.V117.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V117.Discord.HttpError (List ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId, Maybe Evergreen.V117.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V117.Slack.CurrentUser
            , team : Evergreen.V117.Slack.Team
            , users : List Evergreen.V117.Slack.User
            , channels : List ( Evergreen.V117.Slack.Channel, List Evergreen.V117.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Result Effect.Http.Error Evergreen.V117.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Lamdera.ClientId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) Evergreen.V117.Discord.UserAuth (Result Evergreen.V117.Discord.HttpError Evergreen.V117.Discord.User)
    | HandleReadyDataStep2
        (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)
        (Result
            Evergreen.V117.Discord.HttpError
            ( List ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId, Evergreen.V117.DmChannel.DiscordDmChannel, List Evergreen.V117.Discord.Message )
            , List
                ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId
                , { guild : Evergreen.V117.Discord.GatewayGuild
                  , channels : List ( Evergreen.V117.Discord.Channel, List Evergreen.V117.Discord.Message )
                  , icon : Maybe Evergreen.V117.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId, Evergreen.V117.Discord.Channel, List Evergreen.V117.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken
    | NeedsAccountSetup


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | LoggedOutSession
    | AdminToFrontend Evergreen.V117.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V117.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V117.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V117.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V117.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V117.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) Evergreen.V117.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
