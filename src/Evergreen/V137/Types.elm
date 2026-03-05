module Evergreen.V137.Types exposing (..)

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
import Evergreen.V137.AiChat
import Evergreen.V137.ChannelName
import Evergreen.V137.Coord
import Evergreen.V137.CssPixels
import Evergreen.V137.Discord
import Evergreen.V137.Discord.Id
import Evergreen.V137.DiscordAttachmentId
import Evergreen.V137.DmChannel
import Evergreen.V137.Editable
import Evergreen.V137.EmailAddress
import Evergreen.V137.Emoji
import Evergreen.V137.FileStatus
import Evergreen.V137.GuildName
import Evergreen.V137.Id
import Evergreen.V137.ImageEditor
import Evergreen.V137.Local
import Evergreen.V137.LocalState
import Evergreen.V137.Log
import Evergreen.V137.LoginForm
import Evergreen.V137.Message
import Evergreen.V137.MessageInput
import Evergreen.V137.MessageView
import Evergreen.V137.NonemptyDict
import Evergreen.V137.NonemptySet
import Evergreen.V137.OneToOne
import Evergreen.V137.Pages.Admin
import Evergreen.V137.PersonName
import Evergreen.V137.Ports
import Evergreen.V137.Postmark
import Evergreen.V137.RichText
import Evergreen.V137.Route
import Evergreen.V137.SecretId
import Evergreen.V137.SessionIdHash
import Evergreen.V137.Slack
import Evergreen.V137.TextEditor
import Evergreen.V137.Touch
import Evergreen.V137.TwoFactorAuthentication
import Evergreen.V137.Ui.Anim
import Evergreen.V137.User
import Evergreen.V137.UserAgent
import Evergreen.V137.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V137.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V137.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) Evergreen.V137.LocalState.DiscordFrontendGuild
    , user : Evergreen.V137.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V137.SessionIdHash.SessionIdHash Evergreen.V137.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V137.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V137.Route.Route
    , windowSize : Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V137.Ports.NotificationPermission
    , pwaStatus : Evergreen.V137.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V137.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V137.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V137.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))) Evergreen.V137.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V137.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))) Evergreen.V137.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) Evergreen.V137.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.UserSession.ToBeFilledInByBackend (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V137.GuildName.GuildName (Evergreen.V137.UserSession.ToBeFilledInByBackend (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V137.Id.GuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))) (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V137.Id.DiscordGuildOrDmId_DmData (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V137.UserSession.SetViewing
    | Local_SetName Evergreen.V137.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V137.Id.GuildOrDmId (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V137.Id.GuildOrDmId (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V137.Id.DiscordGuildOrDmId (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V137.Id.DiscordGuildOrDmId (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.Message.Message Evergreen.V137.Id.ThreadMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V137.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V137.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V137.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Effect.Time.Posix Evergreen.V137.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))) Evergreen.V137.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V137.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))) Evergreen.V137.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) Evergreen.V137.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V137.LocalState.JoinGuildError
            { guildId : Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId
            , guild : Evergreen.V137.LocalState.FrontendGuild
            , owner : Evergreen.V137.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.GuildOrDmId Evergreen.V137.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.GuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.GuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.GuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))) (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V137.Id.DiscordGuildOrDmId_DmData (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V137.SessionIdHash.SessionIdHash Evergreen.V137.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V137.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V137.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V137.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.NonemptySet.NonemptySet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) Evergreen.V137.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Maybe (Evergreen.V137.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V137.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V137.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V137.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId) (Evergreen.V137.NonemptySet.NonemptySet Int))
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


type alias UserOptionsModel =
    { name : Evergreen.V137.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V137.Local.Local LocalMsg Evergreen.V137.LocalState.LocalState
    , admin : Maybe Evergreen.V137.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId, Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V137.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V137.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.NonemptyDict.NonemptyDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V137.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V137.TextEditor.Model
    , profilePictureEditor : Evergreen.V137.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V137.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V137.NonemptyDict.NonemptyDict Int Evergreen.V137.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V137.NonemptyDict.NonemptyDict Int Evergreen.V137.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V137.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V137.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V137.Ports.NotificationPermission
    , pwaStatus : Evergreen.V137.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V137.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V137.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V137.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V137.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V137.Discord.PartialUser
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V137.Discord.UserAuth
    , user : Evergreen.V137.Discord.User
    , connection : Evergreen.V137.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V137.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V137.Discord.User
    , linkedTo : Evergreen.V137.Id.Id Evergreen.V137.Id.UserId
    , icon : Maybe Evergreen.V137.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V137.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V137.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V137.NonemptyDict.NonemptyDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V137.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V137.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V137.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) Evergreen.V137.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V137.DmChannel.DmChannelId Evergreen.V137.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) Evergreen.V137.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Slack.Id Evergreen.V137.Slack.ChannelId) Evergreen.V137.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V137.OneToOne.OneToOne String (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    , slackUsers : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Slack.Id Evergreen.V137.Slack.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
    , slackServers : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Slack.Id Evergreen.V137.Slack.TeamId) (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    , slackToken : Maybe Evergreen.V137.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V137.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V137.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V137.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V137.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId, Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V137.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V137.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V137.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V137.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.LocalState.LoadingDiscordChannel (List Evergreen.V137.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V137.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V137.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V137.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V137.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V137.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V137.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V137.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V137.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V137.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V137.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V137.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V137.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V137.NonemptyDict.NonemptyDict Int Evergreen.V137.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V137.NonemptyDict.NonemptyDict Int Evergreen.V137.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V137.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V137.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V137.Editable.Msg Evergreen.V137.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V137.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V137.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V137.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ) (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V137.Id.AnyGuildOrDmId Evergreen.V137.Id.ThreadRouteWithMessage Evergreen.V137.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V137.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V137.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) Evergreen.V137.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V137.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V137.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
        , otherUserId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )) Int Evergreen.V137.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )) Int Evergreen.V137.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V137.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V137.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V137.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V137.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute )) Evergreen.V137.PersonName.PersonName Evergreen.V137.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V137.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V137.Id.AnyGuildOrDmId, Evergreen.V137.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V137.Slack.OAuthCode Evergreen.V137.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V137.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V137.ImageEditor.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V137.EmailAddress.EmailAddress (Result Evergreen.V137.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V137.EmailAddress.EmailAddress (Result Evergreen.V137.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Evergreen.V137.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V137.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMaybeMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Result Evergreen.V137.Discord.HttpError Evergreen.V137.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V137.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Result Evergreen.V137.Discord.HttpError Evergreen.V137.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Result Evergreen.V137.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Result Evergreen.V137.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Result Evergreen.V137.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Result Evergreen.V137.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji (Result Evergreen.V137.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji (Result Evergreen.V137.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) Evergreen.V137.Id.ThreadRouteWithMessage (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji (Result Evergreen.V137.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) Evergreen.V137.Emoji.Emoji (Result Evergreen.V137.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V137.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V137.Discord.HttpError (List ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId, Maybe Evergreen.V137.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V137.Slack.CurrentUser
            , team : Evergreen.V137.Slack.Team
            , users : List Evergreen.V137.Slack.User
            , channels : List ( Evergreen.V137.Slack.Channel, List Evergreen.V137.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Result Effect.Http.Error Evergreen.V137.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) Evergreen.V137.Discord.UserAuth (Result Evergreen.V137.Discord.HttpError Evergreen.V137.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Result Evergreen.V137.Discord.HttpError Evergreen.V137.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
        (Result
            Evergreen.V137.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId
                , { guild : Evergreen.V137.Discord.GatewayGuild
                  , channels : List Evergreen.V137.Discord.Channel
                  , icon : Maybe Evergreen.V137.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V137.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.AttachmentId, Evergreen.V137.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V137.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.AttachmentId, Evergreen.V137.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V137.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V137.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V137.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V137.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) (Result Evergreen.V137.Discord.HttpError (List Evergreen.V137.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId) (Result Evergreen.V137.Discord.HttpError (List Evergreen.V137.Discord.Message))


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
    | AdminToFrontend Evergreen.V137.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V137.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V137.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V137.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V137.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V137.ImageEditor.ToFrontend
