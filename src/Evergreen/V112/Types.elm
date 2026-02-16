module Evergreen.V112.Types exposing (..)

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
import Evergreen.V112.AiChat
import Evergreen.V112.ChannelName
import Evergreen.V112.Coord
import Evergreen.V112.CssPixels
import Evergreen.V112.Discord
import Evergreen.V112.Discord.Id
import Evergreen.V112.DmChannel
import Evergreen.V112.Editable
import Evergreen.V112.EmailAddress
import Evergreen.V112.Emoji
import Evergreen.V112.FileStatus
import Evergreen.V112.GuildName
import Evergreen.V112.Id
import Evergreen.V112.ImageEditor
import Evergreen.V112.Local
import Evergreen.V112.LocalState
import Evergreen.V112.Log
import Evergreen.V112.LoginForm
import Evergreen.V112.Message
import Evergreen.V112.MessageInput
import Evergreen.V112.MessageView
import Evergreen.V112.NonemptyDict
import Evergreen.V112.NonemptySet
import Evergreen.V112.OneToOne
import Evergreen.V112.Pages.Admin
import Evergreen.V112.PersonName
import Evergreen.V112.Ports
import Evergreen.V112.Postmark
import Evergreen.V112.RichText
import Evergreen.V112.Route
import Evergreen.V112.SecretId
import Evergreen.V112.SessionIdHash
import Evergreen.V112.Slack
import Evergreen.V112.TextEditor
import Evergreen.V112.Touch
import Evergreen.V112.TwoFactorAuthentication
import Evergreen.V112.Ui.Anim
import Evergreen.V112.User
import Evergreen.V112.UserAgent
import Evergreen.V112.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V112.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V112.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) Evergreen.V112.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) Evergreen.V112.LocalState.DiscordFrontendGuild
    , user : Evergreen.V112.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V112.SessionIdHash.SessionIdHash Evergreen.V112.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V112.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V112.Route.Route
    , windowSize : Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V112.Ports.NotificationPermission
    , pwaStatus : Evergreen.V112.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V112.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V112.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V112.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))) Evergreen.V112.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V112.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))) Evergreen.V112.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) Evergreen.V112.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.UserSession.ToBeFilledInByBackend (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V112.GuildName.GuildName (Evergreen.V112.UserSession.ToBeFilledInByBackend (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V112.Id.GuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))) (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V112.Id.DiscordGuildOrDmId_DmData (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V112.UserSession.SetViewing
    | Local_SetName Evergreen.V112.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V112.Id.GuildOrDmId (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V112.Id.GuildOrDmId (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V112.Id.DiscordGuildOrDmId (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V112.Id.DiscordGuildOrDmId (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.Message.Message Evergreen.V112.Id.ThreadMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V112.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V112.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V112.TextEditor.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Effect.Time.Posix Evergreen.V112.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))) Evergreen.V112.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V112.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))) Evergreen.V112.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) Evergreen.V112.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V112.LocalState.JoinGuildError
            { guildId : Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId
            , guild : Evergreen.V112.LocalState.FrontendGuild
            , owner : Evergreen.V112.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Id.GuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Id.GuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Id.GuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))) (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V112.Id.DiscordGuildOrDmId_DmData (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.FileStatus.FileHash
    | Server_DiscordDirectMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))) (Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId))
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V112.SessionIdHash.SessionIdHash Evergreen.V112.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V112.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V112.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V112.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) String


type LocalMsg
    = LocalChange (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) Evergreen.V112.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V112.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V112.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V112.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId) (Evergreen.V112.NonemptySet.NonemptySet Int))
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


type alias UserOptionsModel =
    { name : Evergreen.V112.Editable.Model
    , slackClientSecret : Evergreen.V112.Editable.Model
    , publicVapidKey : Evergreen.V112.Editable.Model
    , privateVapidKey : Evergreen.V112.Editable.Model
    , openRouterKey : Evergreen.V112.Editable.Model
    , showLinkDiscordSetup : Bool
    , linkDiscordSubmit : LinkDiscordSubmitStatus
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V112.Local.Local LocalMsg Evergreen.V112.LocalState.LocalState
    , admin : Maybe Evergreen.V112.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId, Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V112.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V112.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.NonemptyDict.NonemptyDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V112.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V112.TextEditor.Model
    , profilePictureEditor : Evergreen.V112.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V112.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V112.NonemptyDict.NonemptyDict Int Evergreen.V112.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V112.NonemptyDict.NonemptyDict Int Evergreen.V112.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V112.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V112.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V112.Ports.NotificationPermission
    , pwaStatus : Evergreen.V112.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V112.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V112.UserAgent.UserAgent
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
    , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V112.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V112.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V112.Discord.PartialUser
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V112.Discord.UserAuth
    , user : Evergreen.V112.Discord.User
    , connection : Evergreen.V112.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData


type alias BackendModel =
    { users : Evergreen.V112.NonemptyDict.NonemptyDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V112.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V112.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V112.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) Evergreen.V112.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V112.DmChannel.DmChannelId Evergreen.V112.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) Evergreen.V112.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Slack.Id Evergreen.V112.Slack.ChannelId) Evergreen.V112.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V112.OneToOne.OneToOne String (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    , slackUsers : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Slack.Id Evergreen.V112.Slack.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
    , slackServers : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Slack.Id Evergreen.V112.Slack.TeamId) (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    , slackToken : Maybe Evergreen.V112.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V112.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V112.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V112.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V112.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId, Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V112.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V112.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V112.Local.ChangeId )
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V112.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V112.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V112.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V112.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) Evergreen.V112.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) Evergreen.V112.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V112.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V112.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V112.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V112.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V112.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V112.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V112.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V112.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V112.NonemptyDict.NonemptyDict Int Evergreen.V112.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V112.NonemptyDict.NonemptyDict Int Evergreen.V112.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V112.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V112.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V112.Editable.Msg Evergreen.V112.PersonName.PersonName)
    | SlackClientSecretEditableMsg (Evergreen.V112.Editable.Msg (Maybe Evergreen.V112.Slack.ClientSecret))
    | PublicVapidKeyEditableMsg (Evergreen.V112.Editable.Msg String)
    | PrivateVapidKeyEditableMsg (Evergreen.V112.Editable.Msg Evergreen.V112.LocalState.PrivateVapidKey)
    | OpenRouterKeyEditableMsg (Evergreen.V112.Editable.Msg (Maybe String))
    | ProfilePictureEditorMsg Evergreen.V112.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V112.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V112.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ) (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V112.Id.AnyGuildOrDmId Evergreen.V112.Id.ThreadRouteWithMessage Evergreen.V112.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V112.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V112.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V112.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V112.TextEditor.Msg
    | PressedLinkDiscord
    | TypedBookmarkletData String
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
        , otherUserId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V112.Discord.UserAuth
    , user : Evergreen.V112.Discord.User
    , linkedTo : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , icon : Maybe Evergreen.V112.FileStatus.FileHash
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport


type alias DiscordExport =
    { guildId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId
    , guild : Evergreen.V112.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )) Int Evergreen.V112.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )) Int Evergreen.V112.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V112.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V112.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V112.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V112.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute )) Evergreen.V112.PersonName.PersonName Evergreen.V112.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V112.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V112.Id.AnyGuildOrDmId, Evergreen.V112.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V112.Slack.OAuthCode Evergreen.V112.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V112.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V112.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V112.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V112.EmailAddress.EmailAddress (Result Evergreen.V112.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V112.EmailAddress.EmailAddress (Result Evergreen.V112.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Evergreen.V112.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V112.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMaybeMessage (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Result Evergreen.V112.Discord.HttpError Evergreen.V112.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V112.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))) (SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Result Evergreen.V112.Discord.HttpError Evergreen.V112.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Result Evergreen.V112.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Result Evergreen.V112.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Result Evergreen.V112.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Result Evergreen.V112.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji (Result Evergreen.V112.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji (Result Evergreen.V112.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) Evergreen.V112.Id.ThreadRouteWithMessage (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji (Result Evergreen.V112.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) Evergreen.V112.Emoji.Emoji (Result Evergreen.V112.Discord.HttpError ())
    | CreatedDiscordPrivateChannel Effect.Time.Posix (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Result Evergreen.V112.Discord.HttpError Evergreen.V112.Discord.Channel)
    | AiChatBackendMsg Evergreen.V112.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V112.Discord.HttpError (List ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId, Maybe Evergreen.V112.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V112.Slack.CurrentUser
            , team : Evergreen.V112.Slack.Team
            , users : List Evergreen.V112.Slack.User
            , channels : List ( Evergreen.V112.Slack.Channel, List Evergreen.V112.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Result Effect.Http.Error Evergreen.V112.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Lamdera.ClientId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) Evergreen.V112.Discord.UserAuth (Result Evergreen.V112.Discord.HttpError Evergreen.V112.Discord.User)
    | HandleReadyDataStep2
        (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)
        (Result
            Evergreen.V112.Discord.HttpError
            ( List ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId, Evergreen.V112.DmChannel.DiscordDmChannel, List Evergreen.V112.Discord.Message )
            , List
                ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId
                , { guild : Evergreen.V112.Discord.GatewayGuild
                  , channels : List ( Evergreen.V112.Discord.Channel, List Evergreen.V112.Discord.Message )
                  , icon : Maybe Evergreen.V112.FileStatus.UploadResponse
                  , threads : List ( Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId, Evergreen.V112.Discord.Channel, List Evergreen.V112.Discord.Message )
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Result Effect.Websocket.SendError ())


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
    | AdminToFrontend Evergreen.V112.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V112.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V112.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V112.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V112.Discord.HttpError Evergreen.V112.Discord.User)
    | ProfilePictureEditorToFrontend Evergreen.V112.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) Evergreen.V112.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
