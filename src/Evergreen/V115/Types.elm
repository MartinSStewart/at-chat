module Evergreen.V115.Types exposing (..)

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
import Evergreen.V115.AiChat
import Evergreen.V115.ChannelName
import Evergreen.V115.Coord
import Evergreen.V115.CssPixels
import Evergreen.V115.Discord
import Evergreen.V115.Discord.Id
import Evergreen.V115.DmChannel
import Evergreen.V115.Editable
import Evergreen.V115.EmailAddress
import Evergreen.V115.Emoji
import Evergreen.V115.FileStatus
import Evergreen.V115.GuildName
import Evergreen.V115.Id
import Evergreen.V115.ImageEditor
import Evergreen.V115.Local
import Evergreen.V115.LocalState
import Evergreen.V115.Log
import Evergreen.V115.LoginForm
import Evergreen.V115.Message
import Evergreen.V115.MessageInput
import Evergreen.V115.MessageView
import Evergreen.V115.NonemptyDict
import Evergreen.V115.NonemptySet
import Evergreen.V115.OneToOne
import Evergreen.V115.Pages.Admin
import Evergreen.V115.PersonName
import Evergreen.V115.Ports
import Evergreen.V115.Postmark
import Evergreen.V115.RichText
import Evergreen.V115.Route
import Evergreen.V115.SecretId
import Evergreen.V115.SessionIdHash
import Evergreen.V115.Slack
import Evergreen.V115.TextEditor
import Evergreen.V115.Touch
import Evergreen.V115.TwoFactorAuthentication
import Evergreen.V115.Ui.Anim
import Evergreen.V115.User
import Evergreen.V115.UserAgent
import Evergreen.V115.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V115.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V115.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) Evergreen.V115.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) Evergreen.V115.LocalState.DiscordFrontendGuild
    , user : Evergreen.V115.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V115.SessionIdHash.SessionIdHash Evergreen.V115.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V115.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V115.Route.Route
    , windowSize : Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V115.Ports.NotificationPermission
    , pwaStatus : Evergreen.V115.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V115.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V115.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V115.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))) Evergreen.V115.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V115.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))) Evergreen.V115.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) Evergreen.V115.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.UserSession.ToBeFilledInByBackend (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V115.GuildName.GuildName (Evergreen.V115.UserSession.ToBeFilledInByBackend (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V115.Id.GuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))) (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V115.Id.DiscordGuildOrDmId_DmData (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V115.UserSession.SetViewing
    | Local_SetName Evergreen.V115.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V115.Id.GuildOrDmId (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V115.Id.GuildOrDmId (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V115.Id.DiscordGuildOrDmId (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V115.Id.DiscordGuildOrDmId (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.Message.Message Evergreen.V115.Id.ThreadMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V115.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V115.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V115.TextEditor.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Effect.Time.Posix Evergreen.V115.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))) Evergreen.V115.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V115.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))) Evergreen.V115.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) Evergreen.V115.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V115.LocalState.JoinGuildError
            { guildId : Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId
            , guild : Evergreen.V115.LocalState.FrontendGuild
            , owner : Evergreen.V115.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Id.GuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Id.GuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Id.GuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))) (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V115.Id.DiscordGuildOrDmId_DmData (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.FileStatus.FileHash
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))) (Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V115.SessionIdHash.SessionIdHash Evergreen.V115.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V115.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V115.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V115.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.User.DiscordFrontendCurrentUser
    | Server_DiscordChannelCreated (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.NonemptySet.NonemptySet (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))


type LocalMsg
    = LocalChange (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) Evergreen.V115.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V115.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V115.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V115.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId) (Evergreen.V115.NonemptySet.NonemptySet Int))
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
    | LinkDiscordSubmitError Evergreen.V115.Discord.HttpError


type alias UserOptionsModel =
    { name : Evergreen.V115.Editable.Model
    , slackClientSecret : Evergreen.V115.Editable.Model
    , publicVapidKey : Evergreen.V115.Editable.Model
    , privateVapidKey : Evergreen.V115.Editable.Model
    , openRouterKey : Evergreen.V115.Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V115.Local.Local LocalMsg Evergreen.V115.LocalState.LocalState
    , admin : Maybe Evergreen.V115.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId, Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V115.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V115.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.NonemptyDict.NonemptyDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V115.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V115.TextEditor.Model
    , profilePictureEditor : Evergreen.V115.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V115.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V115.NonemptyDict.NonemptyDict Int Evergreen.V115.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V115.NonemptyDict.NonemptyDict Int Evergreen.V115.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V115.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V115.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V115.Ports.NotificationPermission
    , pwaStatus : Evergreen.V115.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V115.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V115.UserAgent.UserAgent
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
    , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V115.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V115.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V115.Discord.PartialUser
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V115.Discord.UserAuth
    , user : Evergreen.V115.Discord.User
    , connection : Evergreen.V115.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData


type alias BackendModel =
    { users : Evergreen.V115.NonemptyDict.NonemptyDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V115.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V115.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V115.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) Evergreen.V115.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V115.DmChannel.DmChannelId Evergreen.V115.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) Evergreen.V115.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Slack.Id Evergreen.V115.Slack.ChannelId) Evergreen.V115.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V115.OneToOne.OneToOne String (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    , slackUsers : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Slack.Id Evergreen.V115.Slack.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
    , slackServers : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Slack.Id Evergreen.V115.Slack.TeamId) (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    , slackToken : Maybe Evergreen.V115.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V115.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V115.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V115.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V115.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId, Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V115.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V115.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V115.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V115.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V115.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V115.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V115.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) Evergreen.V115.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) Evergreen.V115.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V115.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V115.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V115.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V115.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V115.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V115.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V115.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V115.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V115.NonemptyDict.NonemptyDict Int Evergreen.V115.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V115.NonemptyDict.NonemptyDict Int Evergreen.V115.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V115.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V115.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V115.Editable.Msg Evergreen.V115.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V115.Editable.Msg (Maybe Evergreen.V115.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V115.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V115.Editable.Msg Evergreen.V115.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V115.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V115.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V115.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V115.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ) (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V115.Id.AnyGuildOrDmId Evergreen.V115.Id.ThreadRouteWithMessage Evergreen.V115.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V115.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V115.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V115.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V115.TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
        , otherUserId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V115.Discord.UserAuth
    , user : Evergreen.V115.Discord.User
    , linkedTo : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , icon : Maybe Evergreen.V115.FileStatus.FileHash
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport


type alias DiscordExport =
    { guildId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId
    , guild : Evergreen.V115.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )) Int Evergreen.V115.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )) Int Evergreen.V115.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V115.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V115.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V115.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V115.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute )) Evergreen.V115.PersonName.PersonName Evergreen.V115.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V115.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V115.Id.AnyGuildOrDmId, Evergreen.V115.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V115.Slack.OAuthCode Evergreen.V115.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V115.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V115.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V115.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V115.EmailAddress.EmailAddress (Result Evergreen.V115.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V115.EmailAddress.EmailAddress (Result Evergreen.V115.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Evergreen.V115.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V115.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Result Evergreen.V115.Discord.HttpError Evergreen.V115.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V115.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Result Evergreen.V115.Discord.HttpError Evergreen.V115.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Result Evergreen.V115.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Result Evergreen.V115.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Result Evergreen.V115.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Result Evergreen.V115.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji (Result Evergreen.V115.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji (Result Evergreen.V115.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) Evergreen.V115.Id.ThreadRouteWithMessage (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji (Result Evergreen.V115.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) Evergreen.V115.Emoji.Emoji (Result Evergreen.V115.Discord.HttpError ())
    | CreatedDiscordPrivateChannel Effect.Time.Posix (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Result Evergreen.V115.Discord.HttpError Evergreen.V115.Discord.Channel)
    | AiChatBackendMsg Evergreen.V115.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V115.Discord.HttpError (List ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId, Maybe Evergreen.V115.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V115.Slack.CurrentUser
            , team : Evergreen.V115.Slack.Team
            , users : List Evergreen.V115.Slack.User
            , channels : List ( Evergreen.V115.Slack.Channel, List Evergreen.V115.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Result Effect.Http.Error Evergreen.V115.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Lamdera.ClientId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) Evergreen.V115.Discord.UserAuth (Result Evergreen.V115.Discord.HttpError Evergreen.V115.Discord.User)
    | HandleReadyDataStep2
        (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
        (Result
            Evergreen.V115.Discord.HttpError
            ( List ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId, Evergreen.V115.DmChannel.DiscordDmChannel, List Evergreen.V115.Discord.Message )
            , List
                ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId
                , { guild : Evergreen.V115.Discord.GatewayGuild
                  , channels : List ( Evergreen.V115.Discord.Channel, List Evergreen.V115.Discord.Message )
                  , icon : Maybe Evergreen.V115.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId, Evergreen.V115.Discord.Channel, List Evergreen.V115.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V115.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V115.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V115.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V115.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V115.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V115.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) Evergreen.V115.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
