module Evergreen.V135.Types exposing (..)

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
import Evergreen.V135.AiChat
import Evergreen.V135.ChannelName
import Evergreen.V135.Coord
import Evergreen.V135.CssPixels
import Evergreen.V135.Discord
import Evergreen.V135.Discord.Id
import Evergreen.V135.DiscordAttachmentId
import Evergreen.V135.DmChannel
import Evergreen.V135.Editable
import Evergreen.V135.EmailAddress
import Evergreen.V135.Emoji
import Evergreen.V135.FileStatus
import Evergreen.V135.GuildName
import Evergreen.V135.Id
import Evergreen.V135.ImageEditor
import Evergreen.V135.Local
import Evergreen.V135.LocalState
import Evergreen.V135.Log
import Evergreen.V135.LoginForm
import Evergreen.V135.Message
import Evergreen.V135.MessageInput
import Evergreen.V135.MessageView
import Evergreen.V135.NonemptyDict
import Evergreen.V135.NonemptySet
import Evergreen.V135.OneToOne
import Evergreen.V135.Pages.Admin
import Evergreen.V135.PersonName
import Evergreen.V135.Ports
import Evergreen.V135.Postmark
import Evergreen.V135.RichText
import Evergreen.V135.Route
import Evergreen.V135.SecretId
import Evergreen.V135.SessionIdHash
import Evergreen.V135.Slack
import Evergreen.V135.TextEditor
import Evergreen.V135.Touch
import Evergreen.V135.TwoFactorAuthentication
import Evergreen.V135.Ui.Anim
import Evergreen.V135.User
import Evergreen.V135.UserAgent
import Evergreen.V135.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V135.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V135.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) Evergreen.V135.LocalState.DiscordFrontendGuild
    , user : Evergreen.V135.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V135.SessionIdHash.SessionIdHash Evergreen.V135.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V135.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V135.Route.Route
    , windowSize : Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V135.Ports.NotificationPermission
    , pwaStatus : Evergreen.V135.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V135.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V135.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V135.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))) Evergreen.V135.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V135.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))) Evergreen.V135.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) Evergreen.V135.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.UserSession.ToBeFilledInByBackend (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V135.GuildName.GuildName (Evergreen.V135.UserSession.ToBeFilledInByBackend (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V135.Id.GuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))) (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V135.Id.DiscordGuildOrDmId_DmData (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V135.UserSession.SetViewing
    | Local_SetName Evergreen.V135.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V135.Id.GuildOrDmId (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V135.Id.GuildOrDmId (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V135.Id.DiscordGuildOrDmId (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V135.Id.DiscordGuildOrDmId (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.Message.Message Evergreen.V135.Id.ThreadMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V135.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V135.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V135.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Effect.Time.Posix Evergreen.V135.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))) Evergreen.V135.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V135.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))) Evergreen.V135.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) Evergreen.V135.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V135.LocalState.JoinGuildError
            { guildId : Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId
            , guild : Evergreen.V135.LocalState.FrontendGuild
            , owner : Evergreen.V135.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.GuildOrDmId Evergreen.V135.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.GuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.GuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.GuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))) (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V135.Id.DiscordGuildOrDmId_DmData (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V135.SessionIdHash.SessionIdHash Evergreen.V135.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V135.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V135.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V135.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.NonemptySet.NonemptySet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) Evergreen.V135.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Maybe (Evergreen.V135.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V135.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V135.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V135.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId) (Evergreen.V135.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V135.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V135.Local.Local LocalMsg Evergreen.V135.LocalState.LocalState
    , admin : Maybe Evergreen.V135.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId, Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V135.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V135.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.NonemptyDict.NonemptyDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V135.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V135.TextEditor.Model
    , profilePictureEditor : Evergreen.V135.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V135.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V135.NonemptyDict.NonemptyDict Int Evergreen.V135.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V135.NonemptyDict.NonemptyDict Int Evergreen.V135.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V135.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V135.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V135.Ports.NotificationPermission
    , pwaStatus : Evergreen.V135.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V135.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V135.UserAgent.UserAgent
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
    , userId : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V135.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V135.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V135.Discord.PartialUser
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V135.Discord.UserAuth
    , user : Evergreen.V135.Discord.User
    , connection : Evergreen.V135.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V135.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V135.Discord.User
    , linkedTo : Evergreen.V135.Id.Id Evergreen.V135.Id.UserId
    , icon : Maybe Evergreen.V135.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V135.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V135.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V135.NonemptyDict.NonemptyDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V135.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V135.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V135.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) Evergreen.V135.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V135.DmChannel.DmChannelId Evergreen.V135.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) Evergreen.V135.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Slack.Id Evergreen.V135.Slack.ChannelId) Evergreen.V135.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V135.OneToOne.OneToOne String (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    , slackUsers : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Slack.Id Evergreen.V135.Slack.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
    , slackServers : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Slack.Id Evergreen.V135.Slack.TeamId) (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    , slackToken : Maybe Evergreen.V135.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V135.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V135.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V135.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V135.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId, Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V135.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V135.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V135.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V135.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.LocalState.LoadingDiscordChannel (List Evergreen.V135.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V135.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V135.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V135.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V135.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V135.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V135.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V135.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V135.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V135.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V135.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V135.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V135.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V135.NonemptyDict.NonemptyDict Int Evergreen.V135.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V135.NonemptyDict.NonemptyDict Int Evergreen.V135.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V135.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V135.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V135.Editable.Msg Evergreen.V135.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V135.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V135.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V135.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ) (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V135.Id.AnyGuildOrDmId Evergreen.V135.Id.ThreadRouteWithMessage Evergreen.V135.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V135.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V135.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) Evergreen.V135.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V135.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V135.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
        , otherUserId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )) Int Evergreen.V135.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )) Int Evergreen.V135.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V135.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V135.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V135.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V135.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute )) Evergreen.V135.PersonName.PersonName Evergreen.V135.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V135.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V135.Id.AnyGuildOrDmId, Evergreen.V135.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V135.Slack.OAuthCode Evergreen.V135.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V135.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V135.ImageEditor.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V135.EmailAddress.EmailAddress (Result Evergreen.V135.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V135.EmailAddress.EmailAddress (Result Evergreen.V135.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Evergreen.V135.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V135.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMaybeMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Result Evergreen.V135.Discord.HttpError Evergreen.V135.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V135.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Result Evergreen.V135.Discord.HttpError Evergreen.V135.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Result Evergreen.V135.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Result Evergreen.V135.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Result Evergreen.V135.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Result Evergreen.V135.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji (Result Evergreen.V135.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji (Result Evergreen.V135.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) Evergreen.V135.Id.ThreadRouteWithMessage (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji (Result Evergreen.V135.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) Evergreen.V135.Emoji.Emoji (Result Evergreen.V135.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V135.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V135.Discord.HttpError (List ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId, Maybe Evergreen.V135.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V135.Slack.CurrentUser
            , team : Evergreen.V135.Slack.Team
            , users : List Evergreen.V135.Slack.User
            , channels : List ( Evergreen.V135.Slack.Channel, List Evergreen.V135.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Result Effect.Http.Error Evergreen.V135.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) Evergreen.V135.Discord.UserAuth (Result Evergreen.V135.Discord.HttpError Evergreen.V135.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Result Evergreen.V135.Discord.HttpError Evergreen.V135.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
        (Result
            Evergreen.V135.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId
                , { guild : Evergreen.V135.Discord.GatewayGuild
                  , channels : List Evergreen.V135.Discord.Channel
                  , icon : Maybe Evergreen.V135.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V135.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.AttachmentId, Evergreen.V135.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V135.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.AttachmentId, Evergreen.V135.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V135.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V135.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V135.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V135.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) (Result Evergreen.V135.Discord.HttpError (List Evergreen.V135.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId) (Result Evergreen.V135.Discord.HttpError (List Evergreen.V135.Discord.Message))


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
    | AdminToFrontend Evergreen.V135.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V135.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V135.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V135.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V135.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V135.ImageEditor.ToFrontend
