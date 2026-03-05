module Evergreen.V136.Types exposing (..)

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
import Evergreen.V136.AiChat
import Evergreen.V136.ChannelName
import Evergreen.V136.Coord
import Evergreen.V136.CssPixels
import Evergreen.V136.Discord
import Evergreen.V136.Discord.Id
import Evergreen.V136.DiscordAttachmentId
import Evergreen.V136.DmChannel
import Evergreen.V136.Editable
import Evergreen.V136.EmailAddress
import Evergreen.V136.Emoji
import Evergreen.V136.FileStatus
import Evergreen.V136.GuildName
import Evergreen.V136.Id
import Evergreen.V136.ImageEditor
import Evergreen.V136.Local
import Evergreen.V136.LocalState
import Evergreen.V136.Log
import Evergreen.V136.LoginForm
import Evergreen.V136.Message
import Evergreen.V136.MessageInput
import Evergreen.V136.MessageView
import Evergreen.V136.NonemptyDict
import Evergreen.V136.NonemptySet
import Evergreen.V136.OneToOne
import Evergreen.V136.Pages.Admin
import Evergreen.V136.PersonName
import Evergreen.V136.Ports
import Evergreen.V136.Postmark
import Evergreen.V136.RichText
import Evergreen.V136.Route
import Evergreen.V136.SecretId
import Evergreen.V136.SessionIdHash
import Evergreen.V136.Slack
import Evergreen.V136.TextEditor
import Evergreen.V136.Touch
import Evergreen.V136.TwoFactorAuthentication
import Evergreen.V136.Ui.Anim
import Evergreen.V136.User
import Evergreen.V136.UserAgent
import Evergreen.V136.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V136.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V136.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) Evergreen.V136.LocalState.DiscordFrontendGuild
    , user : Evergreen.V136.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V136.SessionIdHash.SessionIdHash Evergreen.V136.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V136.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V136.Route.Route
    , windowSize : Evergreen.V136.Coord.Coord Evergreen.V136.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V136.Ports.NotificationPermission
    , pwaStatus : Evergreen.V136.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V136.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V136.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V136.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))) Evergreen.V136.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V136.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))) Evergreen.V136.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) Evergreen.V136.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.UserSession.ToBeFilledInByBackend (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V136.GuildName.GuildName (Evergreen.V136.UserSession.ToBeFilledInByBackend (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V136.Id.GuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))) (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V136.Id.DiscordGuildOrDmId_DmData (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V136.UserSession.SetViewing
    | Local_SetName Evergreen.V136.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V136.Id.GuildOrDmId (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V136.Id.GuildOrDmId (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V136.Id.DiscordGuildOrDmId (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V136.Id.DiscordGuildOrDmId (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.Message.Message Evergreen.V136.Id.ThreadMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V136.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V136.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V136.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Effect.Time.Posix Evergreen.V136.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))) Evergreen.V136.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V136.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))) Evergreen.V136.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) Evergreen.V136.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V136.LocalState.JoinGuildError
            { guildId : Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId
            , guild : Evergreen.V136.LocalState.FrontendGuild
            , owner : Evergreen.V136.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.GuildOrDmId Evergreen.V136.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.GuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.GuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.GuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))) (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V136.Id.DiscordGuildOrDmId_DmData (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V136.SessionIdHash.SessionIdHash Evergreen.V136.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V136.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V136.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V136.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.NonemptySet.NonemptySet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) Evergreen.V136.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Maybe (Evergreen.V136.LocalState.LoadingDiscordChannel Int))


type LocalMsg
    = LocalChange (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V136.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V136.Coord.Coord Evergreen.V136.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V136.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V136.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId) (Evergreen.V136.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V136.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V136.Local.Local LocalMsg Evergreen.V136.LocalState.LocalState
    , admin : Maybe Evergreen.V136.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId, Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V136.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V136.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.NonemptyDict.NonemptyDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V136.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V136.TextEditor.Model
    , profilePictureEditor : Evergreen.V136.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V136.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V136.NonemptyDict.NonemptyDict Int Evergreen.V136.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V136.NonemptyDict.NonemptyDict Int Evergreen.V136.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V136.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V136.Coord.Coord Evergreen.V136.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V136.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V136.Ports.NotificationPermission
    , pwaStatus : Evergreen.V136.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V136.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V136.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe String
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type LastRequest
    = NoRequestsMade
    | LastRequest Effect.Time.Posix


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V136.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V136.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V136.Coord.Coord Evergreen.V136.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V136.Discord.PartialUser
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V136.Discord.UserAuth
    , user : Evergreen.V136.Discord.User
    , connection : Evergreen.V136.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V136.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V136.Discord.User
    , linkedTo : Evergreen.V136.Id.Id Evergreen.V136.Id.UserId
    , icon : Maybe Evergreen.V136.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V136.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V136.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V136.NonemptyDict.NonemptyDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V136.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V136.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V136.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) Evergreen.V136.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V136.DmChannel.DmChannelId Evergreen.V136.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) Evergreen.V136.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Slack.Id Evergreen.V136.Slack.ChannelId) Evergreen.V136.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V136.OneToOne.OneToOne String (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    , slackUsers : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Slack.Id Evergreen.V136.Slack.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
    , slackServers : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Slack.Id Evergreen.V136.Slack.TeamId) (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    , slackToken : Maybe Evergreen.V136.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V136.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V136.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V136.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V136.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId, Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V136.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V136.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V136.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V136.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.LocalState.LoadingDiscordChannel (List Evergreen.V136.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V136.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V136.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V136.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V136.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V136.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V136.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Coord.Coord Evergreen.V136.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V136.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V136.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V136.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V136.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V136.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V136.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V136.NonemptyDict.NonemptyDict Int Evergreen.V136.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V136.NonemptyDict.NonemptyDict Int Evergreen.V136.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V136.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V136.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V136.Editable.Msg Evergreen.V136.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V136.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V136.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V136.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ) (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V136.Id.AnyGuildOrDmId Evergreen.V136.Id.ThreadRouteWithMessage Evergreen.V136.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V136.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V136.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) Evergreen.V136.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V136.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V136.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
        , otherUserId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error String)


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )) Int Evergreen.V136.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )) Int Evergreen.V136.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V136.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V136.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V136.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V136.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute )) Evergreen.V136.PersonName.PersonName Evergreen.V136.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V136.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V136.Id.AnyGuildOrDmId, Evergreen.V136.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V136.Slack.OAuthCode Evergreen.V136.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V136.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V136.ImageEditor.ToBackend


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V136.EmailAddress.EmailAddress (Result Evergreen.V136.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V136.EmailAddress.EmailAddress (Result Evergreen.V136.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Evergreen.V136.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V136.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMaybeMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Result Evergreen.V136.Discord.HttpError Evergreen.V136.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V136.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Result Evergreen.V136.Discord.HttpError Evergreen.V136.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Result Evergreen.V136.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Result Evergreen.V136.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Result Evergreen.V136.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Result Evergreen.V136.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji (Result Evergreen.V136.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji (Result Evergreen.V136.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) Evergreen.V136.Id.ThreadRouteWithMessage (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji (Result Evergreen.V136.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) Evergreen.V136.Emoji.Emoji (Result Evergreen.V136.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V136.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V136.Discord.HttpError (List ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId, Maybe Evergreen.V136.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V136.Slack.CurrentUser
            , team : Evergreen.V136.Slack.Team
            , users : List Evergreen.V136.Slack.User
            , channels : List ( Evergreen.V136.Slack.Channel, List Evergreen.V136.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Result Effect.Http.Error Evergreen.V136.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) Evergreen.V136.Discord.UserAuth (Result Evergreen.V136.Discord.HttpError Evergreen.V136.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Result Evergreen.V136.Discord.HttpError Evergreen.V136.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
        (Result
            Evergreen.V136.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId
                , { guild : Evergreen.V136.Discord.GatewayGuild
                  , channels : List Evergreen.V136.Discord.Channel
                  , icon : Maybe Evergreen.V136.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V136.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.AttachmentId, Evergreen.V136.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V136.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.AttachmentId, Evergreen.V136.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V136.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V136.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V136.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V136.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) (Result Evergreen.V136.Discord.HttpError (List Evergreen.V136.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId) (Result Evergreen.V136.Discord.HttpError (List Evergreen.V136.Discord.Message))


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
    | AdminToFrontend Evergreen.V136.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V136.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V136.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V136.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V136.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V136.ImageEditor.ToFrontend
