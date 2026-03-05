module Evergreen.V134.Types exposing (..)

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
import Evergreen.V134.AiChat
import Evergreen.V134.ChannelName
import Evergreen.V134.Coord
import Evergreen.V134.CssPixels
import Evergreen.V134.Discord
import Evergreen.V134.Discord.Id
import Evergreen.V134.DiscordAttachmentId
import Evergreen.V134.DmChannel
import Evergreen.V134.Editable
import Evergreen.V134.EmailAddress
import Evergreen.V134.Emoji
import Evergreen.V134.FileStatus
import Evergreen.V134.GuildName
import Evergreen.V134.Id
import Evergreen.V134.ImageEditor
import Evergreen.V134.Local
import Evergreen.V134.LocalState
import Evergreen.V134.Log
import Evergreen.V134.LoginForm
import Evergreen.V134.Message
import Evergreen.V134.MessageInput
import Evergreen.V134.MessageView
import Evergreen.V134.NonemptyDict
import Evergreen.V134.NonemptySet
import Evergreen.V134.OneToOne
import Evergreen.V134.Pages.Admin
import Evergreen.V134.PersonName
import Evergreen.V134.Ports
import Evergreen.V134.Postmark
import Evergreen.V134.RichText
import Evergreen.V134.Route
import Evergreen.V134.SecretId
import Evergreen.V134.SessionIdHash
import Evergreen.V134.Slack
import Evergreen.V134.TextEditor
import Evergreen.V134.Touch
import Evergreen.V134.TwoFactorAuthentication
import Evergreen.V134.Ui.Anim
import Evergreen.V134.User
import Evergreen.V134.UserAgent
import Evergreen.V134.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V134.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V134.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) Evergreen.V134.LocalState.DiscordFrontendGuild
    , user : Evergreen.V134.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V134.SessionIdHash.SessionIdHash Evergreen.V134.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V134.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V134.Route.Route
    , windowSize : Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V134.Ports.NotificationPermission
    , pwaStatus : Evergreen.V134.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V134.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V134.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V134.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))) Evergreen.V134.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V134.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))) Evergreen.V134.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) Evergreen.V134.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.UserSession.ToBeFilledInByBackend (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V134.GuildName.GuildName (Evergreen.V134.UserSession.ToBeFilledInByBackend (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V134.Id.GuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))) (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V134.Id.DiscordGuildOrDmId_DmData (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V134.UserSession.SetViewing
    | Local_SetName Evergreen.V134.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V134.Id.GuildOrDmId (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V134.Id.GuildOrDmId (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V134.Id.DiscordGuildOrDmId (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V134.Id.DiscordGuildOrDmId (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.Message.Message Evergreen.V134.Id.ThreadMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V134.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V134.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V134.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Effect.Time.Posix Evergreen.V134.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))) Evergreen.V134.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V134.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))) Evergreen.V134.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) Evergreen.V134.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V134.LocalState.JoinGuildError
            { guildId : Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId
            , guild : Evergreen.V134.LocalState.FrontendGuild
            , owner : Evergreen.V134.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.GuildOrDmId Evergreen.V134.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.GuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.GuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.GuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))) (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V134.Id.DiscordGuildOrDmId_DmData (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V134.SessionIdHash.SessionIdHash Evergreen.V134.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V134.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V134.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V134.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.NonemptySet.NonemptySet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) Evergreen.V134.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Maybe (Evergreen.V134.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V134.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V134.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V134.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId) (Evergreen.V134.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V134.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V134.Local.Local LocalMsg Evergreen.V134.LocalState.LocalState
    , admin : Maybe Evergreen.V134.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId, Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V134.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V134.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.NonemptyDict.NonemptyDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V134.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V134.TextEditor.Model
    , profilePictureEditor : Evergreen.V134.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V134.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V134.NonemptyDict.NonemptyDict Int Evergreen.V134.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V134.NonemptyDict.NonemptyDict Int Evergreen.V134.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V134.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V134.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V134.Ports.NotificationPermission
    , pwaStatus : Evergreen.V134.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V134.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V134.UserAgent.UserAgent
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
    , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V134.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V134.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V134.Discord.PartialUser
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V134.Discord.UserAuth
    , user : Evergreen.V134.Discord.User
    , connection : Evergreen.V134.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V134.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V134.Discord.User
    , linkedTo : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , icon : Maybe Evergreen.V134.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V134.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V134.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V134.NonemptyDict.NonemptyDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V134.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V134.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V134.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) Evergreen.V134.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V134.DmChannel.DmChannelId Evergreen.V134.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) Evergreen.V134.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Slack.Id Evergreen.V134.Slack.ChannelId) Evergreen.V134.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V134.OneToOne.OneToOne String (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    , slackUsers : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Slack.Id Evergreen.V134.Slack.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    , slackServers : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Slack.Id Evergreen.V134.Slack.TeamId) (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    , slackToken : Maybe Evergreen.V134.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V134.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V134.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V134.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V134.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId, Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V134.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V134.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V134.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V134.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.LocalState.LoadingDiscordChannel (List Evergreen.V134.Discord.Message))
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V134.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V134.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V134.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V134.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V134.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V134.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V134.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V134.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V134.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V134.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V134.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V134.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V134.NonemptyDict.NonemptyDict Int Evergreen.V134.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V134.NonemptyDict.NonemptyDict Int Evergreen.V134.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V134.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V134.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V134.Editable.Msg Evergreen.V134.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V134.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V134.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V134.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ) (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V134.Id.AnyGuildOrDmId Evergreen.V134.Id.ThreadRouteWithMessage Evergreen.V134.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V134.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V134.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) Evergreen.V134.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V134.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V134.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
        , otherUserId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )) Int Evergreen.V134.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )) Int Evergreen.V134.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V134.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V134.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V134.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V134.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute )) Evergreen.V134.PersonName.PersonName Evergreen.V134.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V134.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V134.Id.AnyGuildOrDmId, Evergreen.V134.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V134.Slack.OAuthCode Evergreen.V134.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V134.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V134.ImageEditor.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V134.EmailAddress.EmailAddress (Result Evergreen.V134.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V134.EmailAddress.EmailAddress (Result Evergreen.V134.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Evergreen.V134.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V134.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMaybeMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Result Evergreen.V134.Discord.HttpError Evergreen.V134.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V134.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Result Evergreen.V134.Discord.HttpError Evergreen.V134.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Result Evergreen.V134.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Result Evergreen.V134.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Result Evergreen.V134.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Result Evergreen.V134.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji (Result Evergreen.V134.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji (Result Evergreen.V134.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) Evergreen.V134.Id.ThreadRouteWithMessage (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji (Result Evergreen.V134.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) Evergreen.V134.Emoji.Emoji (Result Evergreen.V134.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V134.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V134.Discord.HttpError (List ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId, Maybe Evergreen.V134.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V134.Slack.CurrentUser
            , team : Evergreen.V134.Slack.Team
            , users : List Evergreen.V134.Slack.User
            , channels : List ( Evergreen.V134.Slack.Channel, List Evergreen.V134.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Result Effect.Http.Error Evergreen.V134.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Discord.UserAuth (Result Evergreen.V134.Discord.HttpError Evergreen.V134.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Result Evergreen.V134.Discord.HttpError Evergreen.V134.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
        (Result
            Evergreen.V134.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId
                , { guild : Evergreen.V134.Discord.GatewayGuild
                  , channels : List Evergreen.V134.Discord.Channel
                  , icon : Maybe Evergreen.V134.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V134.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.AttachmentId, Evergreen.V134.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V134.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.AttachmentId, Evergreen.V134.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V134.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V134.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V134.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V134.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) (Result Evergreen.V134.Discord.HttpError (List Evergreen.V134.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId) (Result Evergreen.V134.Discord.HttpError (List Evergreen.V134.Discord.Message))


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
    | AdminToFrontend Evergreen.V134.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V134.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V134.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V134.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V134.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V134.ImageEditor.ToFrontend
