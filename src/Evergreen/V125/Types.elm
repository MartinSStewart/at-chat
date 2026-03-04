module Evergreen.V125.Types exposing (..)

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
import Evergreen.V125.AiChat
import Evergreen.V125.ChannelName
import Evergreen.V125.Coord
import Evergreen.V125.CssPixels
import Evergreen.V125.Discord
import Evergreen.V125.Discord.Id
import Evergreen.V125.DiscordAttachmentId
import Evergreen.V125.DmChannel
import Evergreen.V125.Editable
import Evergreen.V125.EmailAddress
import Evergreen.V125.Emoji
import Evergreen.V125.FileStatus
import Evergreen.V125.GuildName
import Evergreen.V125.Id
import Evergreen.V125.ImageEditor
import Evergreen.V125.Local
import Evergreen.V125.LocalState
import Evergreen.V125.Log
import Evergreen.V125.LoginForm
import Evergreen.V125.Message
import Evergreen.V125.MessageInput
import Evergreen.V125.MessageView
import Evergreen.V125.NonemptyDict
import Evergreen.V125.NonemptySet
import Evergreen.V125.OneToOne
import Evergreen.V125.Pages.Admin
import Evergreen.V125.PersonName
import Evergreen.V125.Ports
import Evergreen.V125.Postmark
import Evergreen.V125.RichText
import Evergreen.V125.Route
import Evergreen.V125.SecretId
import Evergreen.V125.SessionIdHash
import Evergreen.V125.Slack
import Evergreen.V125.TextEditor
import Evergreen.V125.Touch
import Evergreen.V125.TwoFactorAuthentication
import Evergreen.V125.Ui.Anim
import Evergreen.V125.User
import Evergreen.V125.UserAgent
import Evergreen.V125.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V125.Pages.Admin.InitAdminData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V125.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) Evergreen.V125.LocalState.DiscordFrontendGuild
    , user : Evergreen.V125.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V125.SessionIdHash.SessionIdHash Evergreen.V125.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V125.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V125.Route.Route
    , windowSize : Evergreen.V125.Coord.Coord Evergreen.V125.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V125.Ports.NotificationPermission
    , pwaStatus : Evergreen.V125.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V125.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V125.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V125.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))) Evergreen.V125.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V125.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))) Evergreen.V125.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) Evergreen.V125.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.UserSession.ToBeFilledInByBackend (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V125.GuildName.GuildName (Evergreen.V125.UserSession.ToBeFilledInByBackend (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V125.Id.GuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))) (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V125.Id.DiscordGuildOrDmId_DmData (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V125.UserSession.SetViewing
    | Local_SetName Evergreen.V125.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V125.Id.GuildOrDmId (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V125.Id.GuildOrDmId (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V125.Id.DiscordGuildOrDmId (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V125.Id.DiscordGuildOrDmId (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.Message.Message Evergreen.V125.Id.ThreadMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V125.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V125.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V125.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)


type ServerChange
    = Server_SendMessage (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Effect.Time.Posix Evergreen.V125.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))) Evergreen.V125.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V125.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))) Evergreen.V125.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) Evergreen.V125.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V125.LocalState.JoinGuildError
            { guildId : Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId
            , guild : Evergreen.V125.LocalState.FrontendGuild
            , owner : Evergreen.V125.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | Server_AddReactionEmoji (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Id.GuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Id.GuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Id.GuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))) (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V125.Id.DiscordGuildOrDmId_DmData (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V125.SessionIdHash.SessionIdHash Evergreen.V125.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V125.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V125.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V125.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | Server_DiscordChannelCreated (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.NonemptySet.NonemptySet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    | Server_DiscordNeedsAuthAgain (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) Evergreen.V125.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | Server_ReloadedDiscordChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) (Result Evergreen.V125.Discord.HttpError ())
    | Server_ReloadedDiscordDmChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Result Evergreen.V125.Discord.HttpError ())


type LocalMsg
    = LocalChange (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) Evergreen.V125.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V125.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V125.Coord.Coord Evergreen.V125.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V125.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V125.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId) (Evergreen.V125.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V125.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V125.Local.Local LocalMsg Evergreen.V125.LocalState.LocalState
    , admin : Maybe Evergreen.V125.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId, Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V125.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V125.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.NonemptyDict.NonemptyDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V125.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V125.TextEditor.Model
    , profilePictureEditor : Evergreen.V125.ImageEditor.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V125.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V125.NonemptyDict.NonemptyDict Int Evergreen.V125.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V125.NonemptyDict.NonemptyDict Int Evergreen.V125.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V125.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V125.Coord.Coord Evergreen.V125.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V125.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V125.Ports.NotificationPermission
    , pwaStatus : Evergreen.V125.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V125.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V125.UserAgent.UserAgent
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
    , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V125.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V125.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V125.Coord.Coord Evergreen.V125.CssPixels.CssPixels)
    }


type alias DiscordBasicUserData =
    { user : Evergreen.V125.Discord.PartialUser
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V125.Discord.UserAuth
    , user : Evergreen.V125.Discord.User
    , connection : Evergreen.V125.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : Evergreen.V125.User.DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V125.Discord.User
    , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V125.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V125.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V125.NonemptyDict.NonemptyDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V125.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V125.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V125.Log.Log
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) Evergreen.V125.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V125.DmChannel.DmChannelId Evergreen.V125.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) Evergreen.V125.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Slack.Id Evergreen.V125.Slack.ChannelId) Evergreen.V125.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V125.OneToOne.OneToOne String (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    , slackUsers : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Slack.Id Evergreen.V125.Slack.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    , slackServers : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Slack.Id Evergreen.V125.Slack.TeamId) (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    , slackToken : Maybe Evergreen.V125.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V125.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V125.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V125.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V125.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId, Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V125.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V125.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V125.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V125.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V125.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V125.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V125.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V125.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) Evergreen.V125.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) Evergreen.V125.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V125.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V125.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Coord.Coord Evergreen.V125.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V125.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V125.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V125.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V125.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V125.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V125.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V125.NonemptyDict.NonemptyDict Int Evergreen.V125.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V125.NonemptyDict.NonemptyDict Int Evergreen.V125.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V125.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V125.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V125.Editable.Msg Evergreen.V125.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V125.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V125.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V125.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ) (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V125.Id.AnyGuildOrDmId Evergreen.V125.Id.ThreadRouteWithMessage Evergreen.V125.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V125.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V125.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V125.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V125.TextEditor.Msg
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
        , otherUserId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
        }
    | PressedDiscordFriendLabel (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId)
    | PressedExportGuild (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | PressedExportDiscordGuild (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | PressedImportGuild
    | GuildImportFileSelected Effect.File.File
    | GotGuildImportFileContent String
    | PressedImportDiscordGuild
    | DiscordGuildImportFileSelected Effect.File.File
    | GotDiscordGuildImportFileContent String
    | TypedDiscordLinkBookmarklet


type alias DiscordFullUserDataExport =
    { auth : Evergreen.V125.Discord.UserAuth
    , user : Evergreen.V125.Discord.User
    , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type alias DiscordNeedsAuthAgainExport =
    { user : Evergreen.V125.Discord.User
    , linkedTo : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , icon : Maybe Evergreen.V125.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserDataExport
    = BasicDataExport DiscordBasicUserData
    | FullDataExport DiscordFullUserDataExport
    | NeedsAuthAgainExport DiscordNeedsAuthAgainExport


type alias DiscordExport =
    { guildId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId
    , guild : Evergreen.V125.LocalState.DiscordBackendGuild
    , users : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) DiscordUserDataExport
    }


type ToBackend
    = CheckLoginRequest (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ))
    | LoginWithTokenRequest (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )) Int Evergreen.V125.UserAgent.UserAgent
    | LoginWithTwoFactorRequest (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )) Int Evergreen.V125.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V125.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V125.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V125.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V125.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)
    | FinishUserCreationRequest (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute )) Evergreen.V125.PersonName.PersonName Evergreen.V125.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V125.AiChat.ToBackend
    | ReloadDataRequest (Maybe ( Evergreen.V125.Id.AnyGuildOrDmId, Evergreen.V125.Id.ThreadRoute ))
    | LinkSlackOAuthCode Evergreen.V125.Slack.OAuthCode Evergreen.V125.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V125.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V125.ImageEditor.ToBackend
    | ExportGuildRequest (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId)
    | ExportDiscordGuildRequest (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId)
    | ImportGuildRequest Evergreen.V125.LocalState.BackendGuild
    | ImportDiscordGuildRequest DiscordExport


type alias DiscordThreadReadyData =
    { channelId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId
    , channel : Evergreen.V125.Discord.Channel
    , messages : List Evergreen.V125.Discord.Message
    , uploadResponses : List (Result Effect.Http.Error ( Evergreen.V125.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V125.FileStatus.UploadResponse ))
    }


type alias ReloadedDiscordChannelData =
    { messages : List Evergreen.V125.Discord.Message
    , attachments : List (Result Effect.Http.Error ( Evergreen.V125.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V125.FileStatus.UploadResponse ))
    , threads : List DiscordThreadReadyData
    }


type alias ReloadedDiscordDmChannelData =
    { messages : List Evergreen.V125.Discord.Message
    , attachments : List (Result Effect.Http.Error ( Evergreen.V125.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V125.FileStatus.UploadResponse ))
    }


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V125.EmailAddress.EmailAddress (Result Evergreen.V125.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V125.EmailAddress.EmailAddress (Result Evergreen.V125.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Evergreen.V125.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V125.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMaybeMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Result Evergreen.V125.Discord.HttpError Evergreen.V125.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V125.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Result Evergreen.V125.Discord.HttpError Evergreen.V125.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Result Evergreen.V125.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Result Evergreen.V125.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Result Evergreen.V125.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Result Evergreen.V125.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji (Result Evergreen.V125.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji (Result Evergreen.V125.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) Evergreen.V125.Id.ThreadRouteWithMessage (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji (Result Evergreen.V125.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) Evergreen.V125.Emoji.Emoji (Result Evergreen.V125.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V125.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V125.Discord.HttpError (List ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId, Maybe Evergreen.V125.FileStatus.UploadResponse )))
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V125.Slack.CurrentUser
            , team : Evergreen.V125.Slack.Team
            , users : List Evergreen.V125.Slack.User
            , channels : List ( Evergreen.V125.Slack.Channel, List Evergreen.V125.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Result Effect.Http.Error Evergreen.V125.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.Discord.UserAuth (Result Evergreen.V125.Discord.HttpError Evergreen.V125.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Result Evergreen.V125.Discord.HttpError Evergreen.V125.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
        (Result
            Evergreen.V125.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId
                , members : List (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
                }
            , List
                ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId
                , { guild : Evergreen.V125.Discord.GatewayGuild
                  , channels : List Evergreen.V125.Discord.Channel
                  , icon : Maybe Evergreen.V125.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V125.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.AttachmentId, Evergreen.V125.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V125.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.AttachmentId, Evergreen.V125.FileStatus.UploadResponse )))
    | ReloadedDiscordChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId) (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) (Result Evergreen.V125.Discord.HttpError ReloadedDiscordChannelData)
    | ReloadedDiscordDmChannel Effect.Time.Posix (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId) (Result Evergreen.V125.Discord.HttpError ReloadedDiscordDmChannelData)


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
    | AdminToFrontend Evergreen.V125.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V125.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V125.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V125.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V125.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V125.ImageEditor.ToFrontend
    | ExportGuildResponse (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) Evergreen.V125.LocalState.BackendGuild
    | ExportDiscordGuildResponse DiscordExport
    | ImportGuildResponse (Result String (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId))
    | ImportDiscordGuildResponse (Result String ())
