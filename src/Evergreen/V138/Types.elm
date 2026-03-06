module Evergreen.V138.Types exposing (..)

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
import Evergreen.V138.AiChat
import Evergreen.V138.ChannelName
import Evergreen.V138.Coord
import Evergreen.V138.CssPixels
import Evergreen.V138.Discord
import Evergreen.V138.Discord.Id
import Evergreen.V138.DiscordAttachmentId
import Evergreen.V138.DmChannel
import Evergreen.V138.Editable
import Evergreen.V138.EmailAddress
import Evergreen.V138.Emoji
import Evergreen.V138.FileStatus
import Evergreen.V138.GuildName
import Evergreen.V138.Id
import Evergreen.V138.ImageEditor
import Evergreen.V138.Local
import Evergreen.V138.LocalState
import Evergreen.V138.Log
import Evergreen.V138.LoginForm
import Evergreen.V138.Message
import Evergreen.V138.MessageInput
import Evergreen.V138.MessageView
import Evergreen.V138.NonemptyDict
import Evergreen.V138.NonemptySet
import Evergreen.V138.OneToOne
import Evergreen.V138.Pages.Admin
import Evergreen.V138.PersonName
import Evergreen.V138.Ports
import Evergreen.V138.Postmark
import Evergreen.V138.RichText
import Evergreen.V138.Route
import Evergreen.V138.SecretId
import Evergreen.V138.SessionIdHash
import Evergreen.V138.Slack
import Evergreen.V138.TextEditor
import Evergreen.V138.Touch
import Evergreen.V138.TwoFactorAuthentication
import Evergreen.V138.Ui.Anim
import Evergreen.V138.User
import Evergreen.V138.UserAgent
import Evergreen.V138.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V138.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V138.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) Evergreen.V138.LocalState.DiscordFrontendGuild
    , user : Evergreen.V138.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V138.SessionIdHash.SessionIdHash Evergreen.V138.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V138.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V138.Route.Route
    , windowSize : Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V138.Ports.NotificationPermission
    , pwaStatus : Evergreen.V138.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V138.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V138.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V138.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))) Evergreen.V138.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V138.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))) Evergreen.V138.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) Evergreen.V138.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.UserSession.ToBeFilledInByBackend (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V138.GuildName.GuildName (Evergreen.V138.UserSession.ToBeFilledInByBackend (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V138.Id.GuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))) (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V138.Id.DiscordGuildOrDmId_DmData (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V138.UserSession.SetViewing
    | Local_SetName Evergreen.V138.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V138.Id.GuildOrDmId (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V138.Id.GuildOrDmId (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V138.Id.DiscordGuildOrDmId (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V138.Id.DiscordGuildOrDmId (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.Message.Message Evergreen.V138.Id.ThreadMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V138.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V138.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V138.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Effect.Time.Posix Evergreen.V138.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))) Evergreen.V138.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V138.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))) Evergreen.V138.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) Evergreen.V138.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V138.LocalState.JoinGuildError
            { guildId : Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId
            , guild : Evergreen.V138.LocalState.FrontendGuild
            , owner : Evergreen.V138.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.GuildOrDmId Evergreen.V138.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.GuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.GuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.GuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))) (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V138.Id.DiscordGuildOrDmId_DmData (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V138.SessionIdHash.SessionIdHash Evergreen.V138.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V138.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V138.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V138.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.NonemptySet.NonemptySet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) Evergreen.V138.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Maybe (Evergreen.V138.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V138.Pages.Admin.InitAdminData


type LocalMsg
    = LocalChange (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V138.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V138.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V138.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId) (Evergreen.V138.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V138.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V138.Local.Local LocalMsg Evergreen.V138.LocalState.LocalState
    , admin : Evergreen.V138.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId, Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V138.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V138.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.NonemptyDict.NonemptyDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V138.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V138.TextEditor.Model
    , profilePictureEditor : Evergreen.V138.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V138.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V138.NonemptyDict.NonemptyDict Int Evergreen.V138.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V138.NonemptyDict.NonemptyDict Int Evergreen.V138.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V138.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V138.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V138.Ports.NotificationPermission
    , pwaStatus : Evergreen.V138.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V138.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V138.UserAgent.UserAgent
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
    , userId : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V138.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V138.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V138.Discord.PartialUser
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V138.Discord.UserAuth
    , user : Evergreen.V138.Discord.User
    , connection : Evergreen.V138.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V138.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V138.Discord.User
    , linkedTo : Evergreen.V138.Id.Id Evergreen.V138.Id.UserId
    , icon : Maybe Evergreen.V138.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V138.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V138.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V138.NonemptyDict.NonemptyDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V138.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V138.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V138.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) Evergreen.V138.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V138.DmChannel.DmChannelId Evergreen.V138.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) Evergreen.V138.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Slack.Id Evergreen.V138.Slack.ChannelId) Evergreen.V138.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V138.OneToOne.OneToOne String (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    , slackUsers : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Slack.Id Evergreen.V138.Slack.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
    , slackServers : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Slack.Id Evergreen.V138.Slack.TeamId) (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    , slackToken : Maybe Evergreen.V138.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V138.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V138.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V138.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V138.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId, Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V138.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V138.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V138.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V138.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.LocalState.LoadingDiscordChannel (List Evergreen.V138.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V138.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V138.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V138.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V138.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V138.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V138.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V138.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V138.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V138.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V138.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V138.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V138.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V138.NonemptyDict.NonemptyDict Int Evergreen.V138.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V138.NonemptyDict.NonemptyDict Int Evergreen.V138.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V138.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V138.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V138.Editable.Msg Evergreen.V138.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V138.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V138.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V138.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V138.Id.AnyGuildOrDmId, Evergreen.V138.Id.ThreadRoute ) (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRouteWithMessage Evergreen.V138.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V138.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V138.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) Evergreen.V138.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V138.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V138.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
        , otherUserId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId)
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V138.Id.AnyGuildOrDmId Evergreen.V138.Id.ThreadRoute
    | InitialLoadRequested_Admin
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V138.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V138.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V138.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V138.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V138.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V138.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V138.PersonName.PersonName Evergreen.V138.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V138.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V138.Slack.OAuthCode Evergreen.V138.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V138.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V138.ImageEditor.ToBackend
    | AdminDataRequest


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V138.EmailAddress.EmailAddress (Result Evergreen.V138.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V138.EmailAddress.EmailAddress (Result Evergreen.V138.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Evergreen.V138.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V138.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMaybeMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Result Evergreen.V138.Discord.HttpError Evergreen.V138.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V138.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Result Evergreen.V138.Discord.HttpError Evergreen.V138.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Result Evergreen.V138.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Result Evergreen.V138.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Result Evergreen.V138.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Result Evergreen.V138.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji (Result Evergreen.V138.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji (Result Evergreen.V138.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) Evergreen.V138.Id.ThreadRouteWithMessage (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji (Result Evergreen.V138.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) Evergreen.V138.Emoji.Emoji (Result Evergreen.V138.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V138.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V138.Discord.HttpError (List ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId, Maybe Evergreen.V138.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V138.Slack.CurrentUser
            , team : Evergreen.V138.Slack.Team
            , users : List Evergreen.V138.Slack.User
            , channels : List ( Evergreen.V138.Slack.Channel, List Evergreen.V138.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Result Effect.Http.Error Evergreen.V138.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) Evergreen.V138.Discord.UserAuth (Result Evergreen.V138.Discord.HttpError Evergreen.V138.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Result Evergreen.V138.Discord.HttpError Evergreen.V138.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
        (Result
            Evergreen.V138.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId
                , { guild : Evergreen.V138.Discord.GatewayGuild
                  , channels : List Evergreen.V138.Discord.Channel
                  , icon : Maybe Evergreen.V138.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V138.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.AttachmentId, Evergreen.V138.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V138.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.AttachmentId, Evergreen.V138.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V138.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V138.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V138.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V138.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) (Result Evergreen.V138.Discord.HttpError (List Evergreen.V138.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId) (Result Evergreen.V138.Discord.HttpError (List Evergreen.V138.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket String Effect.Time.Posix


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
    | AdminToFrontend Evergreen.V138.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V138.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V138.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V138.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V138.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V138.ImageEditor.ToFrontend
