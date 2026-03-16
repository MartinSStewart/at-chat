module Evergreen.V154.Types exposing (..)

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
import Evergreen.V154.AiChat
import Evergreen.V154.ChannelName
import Evergreen.V154.Coord
import Evergreen.V154.CssPixels
import Evergreen.V154.Discord
import Evergreen.V154.DiscordAttachmentId
import Evergreen.V154.DiscordUserData
import Evergreen.V154.DmChannel
import Evergreen.V154.Editable
import Evergreen.V154.EmailAddress
import Evergreen.V154.Emoji
import Evergreen.V154.FileStatus
import Evergreen.V154.GuildName
import Evergreen.V154.Id
import Evergreen.V154.ImageEditor
import Evergreen.V154.Local
import Evergreen.V154.LocalState
import Evergreen.V154.Log
import Evergreen.V154.LoginForm
import Evergreen.V154.Message
import Evergreen.V154.MessageInput
import Evergreen.V154.MessageView
import Evergreen.V154.NonemptyDict
import Evergreen.V154.NonemptySet
import Evergreen.V154.OneToOne
import Evergreen.V154.Pages.Admin
import Evergreen.V154.Pagination
import Evergreen.V154.PersonName
import Evergreen.V154.Ports
import Evergreen.V154.Postmark
import Evergreen.V154.RichText
import Evergreen.V154.Route
import Evergreen.V154.SecretId
import Evergreen.V154.SessionIdHash
import Evergreen.V154.Slack
import Evergreen.V154.TextEditor
import Evergreen.V154.Touch
import Evergreen.V154.TwoFactorAuthentication
import Evergreen.V154.Ui.Anim
import Evergreen.V154.User
import Evergreen.V154.UserAgent
import Evergreen.V154.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V154.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V154.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.LocalState.DiscordFrontendGuild
    , user : Evergreen.V154.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V154.SessionIdHash.SessionIdHash Evergreen.V154.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V154.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V154.Route.Route
    , windowSize : Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V154.Ports.NotificationPermission
    , pwaStatus : Evergreen.V154.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V154.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V154.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V154.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))) Evergreen.V154.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V154.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))) Evergreen.V154.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V154.GuildName.GuildName (Evergreen.V154.UserSession.ToBeFilledInByBackend (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V154.Id.GuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))) (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V154.Id.DiscordGuildOrDmId_DmData (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V154.UserSession.SetViewing
    | Local_SetName Evergreen.V154.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V154.Id.GuildOrDmId (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V154.Id.GuildOrDmId (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V154.Id.DiscordGuildOrDmId (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V154.Id.DiscordGuildOrDmId (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.Message.Message Evergreen.V154.Id.ThreadMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V154.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V154.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V154.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V154.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Effect.Time.Posix Evergreen.V154.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))) Evergreen.V154.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V154.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))) Evergreen.V154.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V154.LocalState.JoinGuildError
            { guildId : Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId
            , guild : Evergreen.V154.LocalState.FrontendGuild
            , owner : Evergreen.V154.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.GuildOrDmId Evergreen.V154.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.GuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.GuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.GuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))) (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V154.Id.DiscordGuildOrDmId_DmData (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V154.SessionIdHash.SessionIdHash Evergreen.V154.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V154.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V154.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V154.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated
        (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId)
        (Evergreen.V154.NonemptyDict.NonemptyDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Maybe (Evergreen.V154.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V154.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V154.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V154.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V154.RichText.EmbedData )


type LocalMsg
    = LocalChange (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V154.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V154.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V154.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId) (Evergreen.V154.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V154.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V154.Local.Local LocalMsg Evergreen.V154.LocalState.LocalState
    , admin : Evergreen.V154.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId, Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V154.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V154.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.NonemptyDict.NonemptyDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V154.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V154.TextEditor.Model
    , profilePictureEditor : Evergreen.V154.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V154.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V154.NonemptyDict.NonemptyDict Int Evergreen.V154.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V154.NonemptyDict.NonemptyDict Int Evergreen.V154.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V154.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V154.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V154.Ports.NotificationPermission
    , pwaStatus : Evergreen.V154.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V154.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V154.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V154.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V154.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V154.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V154.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V154.NonemptyDict.NonemptyDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V154.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V154.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V154.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V154.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V154.DmChannel.DmChannelId Evergreen.V154.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) Evergreen.V154.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Slack.Id Evergreen.V154.Slack.ChannelId) Evergreen.V154.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V154.OneToOne.OneToOne String (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    , slackUsers : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Slack.Id Evergreen.V154.Slack.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
    , slackServers : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Slack.Id Evergreen.V154.Slack.TeamId) (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    , slackToken : Maybe Evergreen.V154.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V154.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V154.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V154.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V154.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId, Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V154.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V154.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V154.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V154.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.LocalState.LoadingDiscordChannel (List Evergreen.V154.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V154.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V154.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V154.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V154.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V154.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V154.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V154.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V154.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V154.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V154.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V154.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V154.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V154.NonemptyDict.NonemptyDict Int Evergreen.V154.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V154.NonemptyDict.NonemptyDict Int Evergreen.V154.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V154.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V154.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V154.Editable.Msg Evergreen.V154.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V154.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V154.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V154.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V154.Id.AnyGuildOrDmId, Evergreen.V154.Id.ThreadRoute ) (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRouteWithMessage Evergreen.V154.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V154.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V154.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) Evergreen.V154.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) Evergreen.V154.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V154.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V154.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
        , otherUserId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V154.RichText.Domain


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V154.Id.AnyGuildOrDmId Evergreen.V154.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V154.Id.Id Evergreen.V154.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V154.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V154.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V154.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V154.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V154.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V154.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V154.PersonName.PersonName Evergreen.V154.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V154.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V154.Slack.OAuthCode Evergreen.V154.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V154.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V154.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V154.Id.Id Evergreen.V154.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V154.EmailAddress.EmailAddress (Result Evergreen.V154.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V154.EmailAddress.EmailAddress (Result Evergreen.V154.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Evergreen.V154.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V154.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMaybeMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Result Evergreen.V154.Discord.HttpError Evergreen.V154.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V154.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Result Evergreen.V154.Discord.HttpError Evergreen.V154.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Result Evergreen.V154.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Result Evergreen.V154.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Result Evergreen.V154.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Result Evergreen.V154.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji (Result Evergreen.V154.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji (Result Evergreen.V154.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji (Result Evergreen.V154.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) Evergreen.V154.Emoji.Emoji (Result Evergreen.V154.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V154.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V154.Discord.HttpError (List ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId, Maybe Evergreen.V154.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V154.Slack.CurrentUser
            , team : Evergreen.V154.Slack.Team
            , users : List Evergreen.V154.Slack.User
            , channels : List ( Evergreen.V154.Slack.Channel, List Evergreen.V154.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Result Effect.Http.Error Evergreen.V154.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) Evergreen.V154.Discord.UserAuth (Result Evergreen.V154.Discord.HttpError Evergreen.V154.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Result Evergreen.V154.Discord.HttpError Evergreen.V154.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
        (Result
            Evergreen.V154.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId
                , members : List (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
                }
            , List
                ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId
                , { guild : Evergreen.V154.Discord.GatewayGuild
                  , channels : List Evergreen.V154.Discord.Channel
                  , icon : Maybe Evergreen.V154.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V154.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.AttachmentId, Evergreen.V154.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V154.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V154.Discord.Id Evergreen.V154.Discord.AttachmentId, Evergreen.V154.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V154.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V154.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V154.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V154.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) (Result Evergreen.V154.Discord.HttpError (List Evergreen.V154.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId) (Result Evergreen.V154.Discord.HttpError (List Evergreen.V154.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) Evergreen.V154.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V154.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V154.DmChannel.DmChannelId Evergreen.V154.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V154.RichText.EmbedData )


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
    | AdminToFrontend Evergreen.V154.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V154.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V154.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V154.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V154.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V154.ImageEditor.ToFrontend
