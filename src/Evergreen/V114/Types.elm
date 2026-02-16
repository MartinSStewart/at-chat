module Evergreen.V114.Types exposing (..)

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
import Evergreen.V114.AiChat
import Evergreen.V114.ChannelName
import Evergreen.V114.Coord
import Evergreen.V114.CssPixels
import Evergreen.V114.Discord
import Evergreen.V114.Discord.Id
import Evergreen.V114.DmChannel
import Evergreen.V114.Editable
import Evergreen.V114.EmailAddress
import Evergreen.V114.Emoji
import Evergreen.V114.FileStatus
import Evergreen.V114.GuildName
import Evergreen.V114.Id
import Evergreen.V114.ImageEditor
import Evergreen.V114.Local
import Evergreen.V114.LocalState
import Evergreen.V114.Log
import Evergreen.V114.LoginForm
import Evergreen.V114.Message
import Evergreen.V114.MessageInput
import Evergreen.V114.MessageView
import Evergreen.V114.NonemptyDict
import Evergreen.V114.NonemptySet
import Evergreen.V114.OneToOne
import Evergreen.V114.Pages.Admin
import Evergreen.V114.PersonName
import Evergreen.V114.Ports
import Evergreen.V114.Postmark
import Evergreen.V114.RichText
import Evergreen.V114.Route
import Evergreen.V114.SecretId
import Evergreen.V114.SessionIdHash
import Evergreen.V114.Slack
import Evergreen.V114.TextEditor
import Evergreen.V114.Touch
import Evergreen.V114.TwoFactorAuthentication
import Evergreen.V114.Ui.Anim
import Evergreen.V114.User
import Evergreen.V114.UserAgent
import Evergreen.V114.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V114.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V114.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) Evergreen.V114.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) Evergreen.V114.LocalState.DiscordFrontendGuild
    , user : Evergreen.V114.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V114.SessionIdHash.SessionIdHash Evergreen.V114.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V114.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V114.Route.Route
    , windowSize : Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V114.Ports.NotificationPermission
    , pwaStatus : Evergreen.V114.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V114.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V114.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V114.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))) Evergreen.V114.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V114.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))) Evergreen.V114.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) Evergreen.V114.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.UserSession.ToBeFilledInByBackend (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V114.GuildName.GuildName (Evergreen.V114.UserSession.ToBeFilledInByBackend (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V114.Id.GuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))) (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V114.Id.DiscordGuildOrDmId_DmData (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V114.UserSession.SetViewing
    | Local_SetName Evergreen.V114.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V114.Id.GuildOrDmId (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V114.Id.GuildOrDmId (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V114.Id.DiscordGuildOrDmId (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V114.Id.DiscordGuildOrDmId (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.Message.Message Evergreen.V114.Id.ThreadMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V114.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V114.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V114.TextEditor.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Effect.Time.Posix Evergreen.V114.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))) Evergreen.V114.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V114.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))) Evergreen.V114.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) Evergreen.V114.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V114.LocalState.JoinGuildError
            { guildId : Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId
            , guild : Evergreen.V114.LocalState.FrontendGuild
            , owner : Evergreen.V114.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Id.GuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Id.GuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Id.GuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))) (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V114.Id.DiscordGuildOrDmId_DmData (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.FileStatus.FileHash
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))) (Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V114.SessionIdHash.SessionIdHash Evergreen.V114.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V114.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V114.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V114.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) String


type LocalMsg
    = LocalChange (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) Evergreen.V114.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V114.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V114.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V114.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId) (Evergreen.V114.NonemptySet.NonemptySet Int))
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
    | LinkDiscordSubmitError Evergreen.V114.Discord.HttpError


type alias UserOptionsModel =
    { name : Evergreen.V114.Editable.Model
    , slackClientSecret : Evergreen.V114.Editable.Model
    , publicVapidKey : Evergreen.V114.Editable.Model
    , privateVapidKey : Evergreen.V114.Editable.Model
    , openRouterKey : Evergreen.V114.Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V114.Local.Local LocalMsg Evergreen.V114.LocalState.LocalState
    , admin : Maybe Evergreen.V114.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId, Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V114.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V114.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.NonemptyDict.NonemptyDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V114.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V114.TextEditor.Model
    , profilePictureEditor : Evergreen.V114.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V114.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V114.NonemptyDict.NonemptyDict Int Evergreen.V114.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V114.NonemptyDict.NonemptyDict Int Evergreen.V114.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V114.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V114.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V114.Ports.NotificationPermission
    , pwaStatus : Evergreen.V114.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V114.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V114.UserAgent.UserAgent
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
    , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V114.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V114.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V114.Discord.PartialUser
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V114.Discord.UserAuth
    , user : Evergreen.V114.Discord.User
    , connection : Evergreen.V114.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData


type alias BackendModel =
    { users : Evergreen.V114.NonemptyDict.NonemptyDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V114.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V114.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V114.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) Evergreen.V114.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V114.DmChannel.DmChannelId Evergreen.V114.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) Evergreen.V114.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Slack.Id Evergreen.V114.Slack.ChannelId) Evergreen.V114.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V114.OneToOne.OneToOne String (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    , slackUsers : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Slack.Id Evergreen.V114.Slack.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
    , slackServers : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Slack.Id Evergreen.V114.Slack.TeamId) (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    , slackToken : Maybe Evergreen.V114.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V114.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V114.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V114.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V114.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId, Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V114.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V114.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V114.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V114.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V114.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V114.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V114.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) Evergreen.V114.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) Evergreen.V114.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V114.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V114.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V114.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V114.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V114.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V114.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V114.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V114.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V114.NonemptyDict.NonemptyDict Int Evergreen.V114.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V114.NonemptyDict.NonemptyDict Int Evergreen.V114.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V114.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V114.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V114.Editable.Msg Evergreen.V114.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V114.Editable.Msg (Maybe Evergreen.V114.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V114.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V114.Editable.Msg Evergreen.V114.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V114.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V114.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V114.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V114.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ) (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V114.Id.AnyGuildOrDmId Evergreen.V114.Id.ThreadRouteWithMessage Evergreen.V114.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V114.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V114.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V114.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V114.TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
        , otherUserId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V114.Discord.UserAuth
    , user : Evergreen.V114.Discord.User
    , linkedTo : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , icon : Maybe Evergreen.V114.FileStatus.FileHash
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport


type alias DiscordExport =
    { guildId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId
    , guild : Evergreen.V114.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )) Int Evergreen.V114.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )) Int Evergreen.V114.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V114.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V114.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V114.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V114.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute )) Evergreen.V114.PersonName.PersonName Evergreen.V114.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V114.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V114.Id.AnyGuildOrDmId, Evergreen.V114.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V114.Slack.OAuthCode Evergreen.V114.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V114.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V114.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V114.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V114.EmailAddress.EmailAddress (Result Evergreen.V114.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V114.EmailAddress.EmailAddress (Result Evergreen.V114.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Evergreen.V114.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V114.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Result Evergreen.V114.Discord.HttpError Evergreen.V114.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V114.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V114.RichText.RichText (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.FileStatus.FileId) Evergreen.V114.FileStatus.FileData) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Result Evergreen.V114.Discord.HttpError Evergreen.V114.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Result Evergreen.V114.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Result Evergreen.V114.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Result Evergreen.V114.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Result Evergreen.V114.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji (Result Evergreen.V114.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji (Result Evergreen.V114.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) Evergreen.V114.Id.ThreadRouteWithMessage (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji (Result Evergreen.V114.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) Evergreen.V114.Emoji.Emoji (Result Evergreen.V114.Discord.HttpError ())
    | CreatedDiscordPrivateChannel Effect.Time.Posix (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Result Evergreen.V114.Discord.HttpError Evergreen.V114.Discord.Channel)
    | AiChatBackendMsg Evergreen.V114.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V114.Discord.HttpError (List ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId, Maybe Evergreen.V114.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V114.Slack.CurrentUser
            , team : Evergreen.V114.Slack.Team
            , users : List Evergreen.V114.Slack.User
            , channels : List ( Evergreen.V114.Slack.Channel, List Evergreen.V114.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Result Effect.Http.Error Evergreen.V114.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Lamdera.ClientId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) Evergreen.V114.Discord.UserAuth (Result Evergreen.V114.Discord.HttpError Evergreen.V114.Discord.User)
    | HandleReadyDataStep2
        (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)
        (Result
            Evergreen.V114.Discord.HttpError
            ( List ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId, Evergreen.V114.DmChannel.DiscordDmChannel, List Evergreen.V114.Discord.Message )
            , List
                ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId
                , { guild : Evergreen.V114.Discord.GatewayGuild
                  , channels : List ( Evergreen.V114.Discord.Channel, List Evergreen.V114.Discord.Message )
                  , icon : Maybe Evergreen.V114.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId, Evergreen.V114.Discord.Channel, List Evergreen.V114.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V114.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V114.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V114.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V114.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V114.Discord.HttpError Evergreen.V114.Discord.User)
    | ProfilePictureEditorToFrontend Evergreen.V114.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) Evergreen.V114.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
