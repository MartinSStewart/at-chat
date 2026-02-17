module Evergreen.V116.Types exposing (..)

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
import Evergreen.V116.AiChat
import Evergreen.V116.ChannelName
import Evergreen.V116.Coord
import Evergreen.V116.CssPixels
import Evergreen.V116.Discord
import Evergreen.V116.Discord.Id
import Evergreen.V116.DmChannel
import Evergreen.V116.Editable
import Evergreen.V116.EmailAddress
import Evergreen.V116.Emoji
import Evergreen.V116.FileStatus
import Evergreen.V116.GuildName
import Evergreen.V116.Id
import Evergreen.V116.ImageEditor
import Evergreen.V116.Local
import Evergreen.V116.LocalState
import Evergreen.V116.Log
import Evergreen.V116.LoginForm
import Evergreen.V116.Message
import Evergreen.V116.MessageInput
import Evergreen.V116.MessageView
import Evergreen.V116.NonemptyDict
import Evergreen.V116.NonemptySet
import Evergreen.V116.OneToOne
import Evergreen.V116.Pages.Admin
import Evergreen.V116.PersonName
import Evergreen.V116.Ports
import Evergreen.V116.Postmark
import Evergreen.V116.RichText
import Evergreen.V116.Route
import Evergreen.V116.SecretId
import Evergreen.V116.SessionIdHash
import Evergreen.V116.Slack
import Evergreen.V116.TextEditor
import Evergreen.V116.Touch
import Evergreen.V116.TwoFactorAuthentication
import Evergreen.V116.Ui.Anim
import Evergreen.V116.User
import Evergreen.V116.UserAgent
import Evergreen.V116.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V116.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V116.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) Evergreen.V116.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) Evergreen.V116.LocalState.DiscordFrontendGuild
    , user : Evergreen.V116.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V116.SessionIdHash.SessionIdHash Evergreen.V116.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V116.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V116.Route.Route
    , windowSize : Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V116.Ports.NotificationPermission
    , pwaStatus : Evergreen.V116.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V116.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V116.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V116.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))) Evergreen.V116.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V116.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))) Evergreen.V116.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) Evergreen.V116.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.UserSession.ToBeFilledInByBackend (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V116.GuildName.GuildName (Evergreen.V116.UserSession.ToBeFilledInByBackend (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V116.Id.GuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))) (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V116.Id.DiscordGuildOrDmId_DmData (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V116.UserSession.SetViewing
    | Local_SetName Evergreen.V116.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V116.Id.GuildOrDmId (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V116.Id.GuildOrDmId (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V116.Id.DiscordGuildOrDmId (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V116.Id.DiscordGuildOrDmId (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.Message.Message Evergreen.V116.Id.ThreadMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V116.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V116.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V116.TextEditor.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Effect.Time.Posix Evergreen.V116.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))) Evergreen.V116.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V116.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))) Evergreen.V116.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) Evergreen.V116.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V116.LocalState.JoinGuildError
            { guildId : Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId
            , guild : Evergreen.V116.LocalState.FrontendGuild
            , owner : Evergreen.V116.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Id.GuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Id.GuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Id.GuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))) (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V116.Id.DiscordGuildOrDmId_DmData (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.FileStatus.FileHash
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))) (Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V116.SessionIdHash.SessionIdHash Evergreen.V116.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V116.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V116.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V116.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.User.DiscordFrontendCurrentUser
    | Server_DiscordChannelCreated (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.NonemptySet.NonemptySet (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))


type LocalMsg
    = LocalChange (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) Evergreen.V116.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V116.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V116.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V116.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId) (Evergreen.V116.NonemptySet.NonemptySet Int))
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
    | LinkDiscordSubmitError Evergreen.V116.Discord.HttpError


type alias UserOptionsModel =
    { name : Evergreen.V116.Editable.Model
    , slackClientSecret : Evergreen.V116.Editable.Model
    , publicVapidKey : Evergreen.V116.Editable.Model
    , privateVapidKey : Evergreen.V116.Editable.Model
    , openRouterKey : Evergreen.V116.Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V116.Local.Local LocalMsg Evergreen.V116.LocalState.LocalState
    , admin : Maybe Evergreen.V116.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId, Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V116.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V116.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.NonemptyDict.NonemptyDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V116.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V116.TextEditor.Model
    , profilePictureEditor : Evergreen.V116.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V116.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V116.NonemptyDict.NonemptyDict Int Evergreen.V116.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V116.NonemptyDict.NonemptyDict Int Evergreen.V116.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V116.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V116.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V116.Ports.NotificationPermission
    , pwaStatus : Evergreen.V116.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V116.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V116.UserAgent.UserAgent
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
    , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V116.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V116.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V116.Discord.PartialUser
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V116.Discord.UserAuth
    , user : Evergreen.V116.Discord.User
    , connection : Evergreen.V116.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V116.Discord.User
    , linkedTo : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias BackendModel =
    { users : Evergreen.V116.NonemptyDict.NonemptyDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V116.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V116.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V116.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) Evergreen.V116.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V116.DmChannel.DmChannelId Evergreen.V116.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) Evergreen.V116.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Slack.Id Evergreen.V116.Slack.ChannelId) Evergreen.V116.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V116.OneToOne.OneToOne String (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    , slackUsers : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Slack.Id Evergreen.V116.Slack.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
    , slackServers : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Slack.Id Evergreen.V116.Slack.TeamId) (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    , slackToken : Maybe Evergreen.V116.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V116.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V116.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V116.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V116.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId, Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V116.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V116.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V116.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V116.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V116.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V116.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V116.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) Evergreen.V116.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) Evergreen.V116.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V116.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V116.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V116.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V116.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V116.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V116.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V116.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V116.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V116.NonemptyDict.NonemptyDict Int Evergreen.V116.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V116.NonemptyDict.NonemptyDict Int Evergreen.V116.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V116.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V116.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V116.Editable.Msg Evergreen.V116.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V116.Editable.Msg (Maybe Evergreen.V116.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V116.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V116.Editable.Msg Evergreen.V116.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V116.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V116.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V116.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V116.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ) (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V116.Id.AnyGuildOrDmId Evergreen.V116.Id.ThreadRouteWithMessage Evergreen.V116.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V116.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V116.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V116.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V116.TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
        , otherUserId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V116.Discord.UserAuth
    , user : Evergreen.V116.Discord.User
    , linkedTo : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V116.Discord.User
    , linkedTo : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , icon : Maybe Evergreen.V116.FileStatus.FileHash
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId
    , guild : Evergreen.V116.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )) Int Evergreen.V116.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )) Int Evergreen.V116.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V116.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V116.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V116.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V116.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute )) Evergreen.V116.PersonName.PersonName Evergreen.V116.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V116.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V116.Id.AnyGuildOrDmId, Evergreen.V116.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V116.Slack.OAuthCode Evergreen.V116.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V116.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V116.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V116.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V116.EmailAddress.EmailAddress (Result Evergreen.V116.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V116.EmailAddress.EmailAddress (Result Evergreen.V116.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Evergreen.V116.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V116.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Result Evergreen.V116.Discord.HttpError Evergreen.V116.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V116.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V116.RichText.RichText (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.FileStatus.FileId) Evergreen.V116.FileStatus.FileData) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Result Evergreen.V116.Discord.HttpError Evergreen.V116.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Result Evergreen.V116.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Result Evergreen.V116.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Result Evergreen.V116.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Result Evergreen.V116.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji (Result Evergreen.V116.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji (Result Evergreen.V116.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) Evergreen.V116.Id.ThreadRouteWithMessage (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji (Result Evergreen.V116.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) Evergreen.V116.Emoji.Emoji (Result Evergreen.V116.Discord.HttpError ())
    | CreatedDiscordPrivateChannel Effect.Time.Posix (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Result Evergreen.V116.Discord.HttpError Evergreen.V116.Discord.Channel)
    | AiChatBackendMsg Evergreen.V116.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V116.Discord.HttpError (List ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId, Maybe Evergreen.V116.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V116.Slack.CurrentUser
            , team : Evergreen.V116.Slack.Team
            , users : List Evergreen.V116.Slack.User
            , channels : List ( Evergreen.V116.Slack.Channel, List Evergreen.V116.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Result Effect.Http.Error Evergreen.V116.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Lamdera.ClientId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) Evergreen.V116.Discord.UserAuth (Result Evergreen.V116.Discord.HttpError Evergreen.V116.Discord.User)
    | HandleReadyDataStep2
        (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)
        (Result
            Evergreen.V116.Discord.HttpError
            ( List ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId, Evergreen.V116.DmChannel.DiscordDmChannel, List Evergreen.V116.Discord.Message )
            , List
                ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId
                , { guild : Evergreen.V116.Discord.GatewayGuild
                  , channels : List ( Evergreen.V116.Discord.Channel, List Evergreen.V116.Discord.Message )
                  , icon : Maybe Evergreen.V116.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId, Evergreen.V116.Discord.Channel, List Evergreen.V116.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V116.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V116.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V116.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V116.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V116.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V116.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) Evergreen.V116.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
