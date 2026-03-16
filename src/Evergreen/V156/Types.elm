module Evergreen.V156.Types exposing (..)

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
import Evergreen.V156.AiChat
import Evergreen.V156.ChannelName
import Evergreen.V156.Coord
import Evergreen.V156.CssPixels
import Evergreen.V156.Discord
import Evergreen.V156.DiscordAttachmentId
import Evergreen.V156.DiscordUserData
import Evergreen.V156.DmChannel
import Evergreen.V156.Editable
import Evergreen.V156.EmailAddress
import Evergreen.V156.Emoji
import Evergreen.V156.FileStatus
import Evergreen.V156.GuildName
import Evergreen.V156.Id
import Evergreen.V156.ImageEditor
import Evergreen.V156.Local
import Evergreen.V156.LocalState
import Evergreen.V156.Log
import Evergreen.V156.LoginForm
import Evergreen.V156.Message
import Evergreen.V156.MessageInput
import Evergreen.V156.MessageView
import Evergreen.V156.NonemptyDict
import Evergreen.V156.NonemptySet
import Evergreen.V156.OneToOne
import Evergreen.V156.Pages.Admin
import Evergreen.V156.Pagination
import Evergreen.V156.PersonName
import Evergreen.V156.Ports
import Evergreen.V156.Postmark
import Evergreen.V156.RichText
import Evergreen.V156.Route
import Evergreen.V156.SecretId
import Evergreen.V156.SessionIdHash
import Evergreen.V156.Slack
import Evergreen.V156.TextEditor
import Evergreen.V156.Touch
import Evergreen.V156.TwoFactorAuthentication
import Evergreen.V156.Ui.Anim
import Evergreen.V156.User
import Evergreen.V156.UserAgent
import Evergreen.V156.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V156.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V156.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.LocalState.DiscordFrontendGuild
    , user : Evergreen.V156.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V156.SessionIdHash.SessionIdHash Evergreen.V156.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V156.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V156.Route.Route
    , windowSize : Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V156.Ports.NotificationPermission
    , pwaStatus : Evergreen.V156.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V156.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V156.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V156.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))) Evergreen.V156.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V156.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))) Evergreen.V156.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V156.GuildName.GuildName (Evergreen.V156.UserSession.ToBeFilledInByBackend (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V156.Id.GuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))) (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V156.Id.DiscordGuildOrDmId_DmData (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V156.UserSession.SetViewing
    | Local_SetName Evergreen.V156.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V156.Id.GuildOrDmId (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V156.Id.GuildOrDmId (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V156.Id.DiscordGuildOrDmId (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V156.Id.DiscordGuildOrDmId (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.Message.Message Evergreen.V156.Id.ThreadMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V156.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V156.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V156.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V156.RichText.Domain


type ServerChange
    = Server_SendMessage (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Effect.Time.Posix Evergreen.V156.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))) Evergreen.V156.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V156.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))) Evergreen.V156.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V156.LocalState.JoinGuildError
            { guildId : Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId
            , guild : Evergreen.V156.LocalState.FrontendGuild
            , owner : Evergreen.V156.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.GuildOrDmId Evergreen.V156.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.GuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.GuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.GuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))) (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V156.Id.DiscordGuildOrDmId_DmData (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V156.SessionIdHash.SessionIdHash Evergreen.V156.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V156.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V156.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V156.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.ChannelName.ChannelName
    | Server_DiscordDmChannelCreated
        (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId)
        (Evergreen.V156.NonemptyDict.NonemptyDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Maybe (Evergreen.V156.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V156.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V156.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V156.RichText.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Id.ThreadRouteWithMessage ( Int, Result () Evergreen.V156.RichText.EmbedData )


type LocalMsg
    = LocalChange (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V156.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V156.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V156.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId) (Evergreen.V156.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V156.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V156.Local.Local LocalMsg Evergreen.V156.LocalState.LocalState
    , admin : Evergreen.V156.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId, Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , pingUser : Maybe Evergreen.V156.MessageInput.MentionUserDropdown
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V156.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.NonemptyDict.NonemptyDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V156.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V156.TextEditor.Model
    , profilePictureEditor : Evergreen.V156.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V156.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V156.NonemptyDict.NonemptyDict Int Evergreen.V156.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V156.NonemptyDict.NonemptyDict Int Evergreen.V156.Touch.Touch
        }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V156.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V156.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , textInputFocus : Maybe Effect.Browser.Dom.HtmlId
    , notificationPermission : Evergreen.V156.Ports.NotificationPermission
    , pwaStatus : Evergreen.V156.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V156.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V156.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V156.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V156.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V156.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V156.FileStatus.ImageMetadata
    }


type alias BackendModel =
    { users : Evergreen.V156.NonemptyDict.NonemptyDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V156.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V156.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V156.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V156.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V156.DmChannel.DmChannelId Evergreen.V156.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) Evergreen.V156.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Slack.Id Evergreen.V156.Slack.ChannelId) Evergreen.V156.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V156.OneToOne.OneToOne String (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    , slackUsers : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Slack.Id Evergreen.V156.Slack.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
    , slackServers : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Slack.Id Evergreen.V156.Slack.TeamId) (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    , slackToken : Maybe Evergreen.V156.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V156.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V156.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V156.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V156.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId, Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V156.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V156.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V156.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V156.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.LocalState.LoadingDiscordChannel (List Evergreen.V156.Discord.Message))
    , signupsEnabled : Bool
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V156.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V156.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V156.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V156.Route.Route
    | PressedTextInput
    | TypedMessage ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) String
    | PressedSendMessage Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRoute
    | PressedAttachFiles ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | SelectedFilesToAttach ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition (Result Effect.Browser.Dom.Error Evergreen.V156.MessageInput.MentionUserDropdown)
    | PressedPingUser ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) Int
    | SetFocus
    | RemoveFocus
    | PressedArrowInDropdown Evergreen.V156.Id.AnyGuildOrDmId Int
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels)
    | MessageMenu_PressedEditMessage Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | PressedEmojiSelectorEmoji Evergreen.V156.Emoji.Emoji
    | GotPingUserPositionForEditMessage (Result Effect.Browser.Dom.Error Evergreen.V156.MessageInput.MentionUserDropdown)
    | TypedEditMessage ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) String
    | PressedSendEditMessage ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | PressedArrowInDropdownForEditMessage Evergreen.V156.Id.AnyGuildOrDmId Int
    | PressedPingUserForEditMessage ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) Int
    | PressedArrowUpInEmptyInput ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | MessageMenu_PressedReply Evergreen.V156.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V156.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V156.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V156.NonemptyDict.NonemptyDict Int Evergreen.V156.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V156.NonemptyDict.NonemptyDict Int Evergreen.V156.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRoute ScrollPosition
    | PressedBody
    | PressedReactionEmojiContainer
    | MessageMenu_PressedDeleteMessage Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | PressedPingDropdownContainer
    | PressedEditMessagePingDropdownContainer
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V156.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V156.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V156.Editable.Msg Evergreen.V156.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V156.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V156.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId)
    | EditMessage_PressedAttachFiles ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute )
    | EditMessage_SelectedFilesToAttach ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V156.FileStatus.UploadResponse)
    | EditMessage_PastedFiles ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | PastedFiles ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (List.Nonempty.Nonempty Effect.File.File)
    | FileUploadProgress ( Evergreen.V156.Id.AnyGuildOrDmId, Evergreen.V156.Id.ThreadRoute ) (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRouteWithMessage Evergreen.V156.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V156.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V156.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) Evergreen.V156.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) Evergreen.V156.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V156.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V156.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
        , otherUserId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V156.RichText.Domain
    | PressedContinueToSite


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V156.Id.AnyGuildOrDmId Evergreen.V156.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V156.Id.Id Evergreen.V156.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V156.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V156.UserAgent.UserAgent
    | GetLoginTokenRequest Evergreen.V156.EmailAddress.EmailAddress
    | AdminToBackend Evergreen.V156.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V156.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V156.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V156.PersonName.PersonName Evergreen.V156.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V156.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V156.Slack.OAuthCode Evergreen.V156.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V156.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V156.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V156.Id.Id Evergreen.V156.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V156.EmailAddress.EmailAddress (Result Evergreen.V156.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V156.EmailAddress.EmailAddress (Result Evergreen.V156.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Evergreen.V156.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V156.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMaybeMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Result Evergreen.V156.Discord.HttpError Evergreen.V156.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V156.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Result Evergreen.V156.Discord.HttpError Evergreen.V156.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Result Evergreen.V156.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Result Evergreen.V156.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Result Evergreen.V156.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Result Evergreen.V156.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji (Result Evergreen.V156.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji (Result Evergreen.V156.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji (Result Evergreen.V156.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) Evergreen.V156.Emoji.Emoji (Result Evergreen.V156.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V156.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V156.Discord.HttpError (List ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId, Maybe Evergreen.V156.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V156.Slack.CurrentUser
            , team : Evergreen.V156.Slack.Team
            , users : List Evergreen.V156.Slack.User
            , channels : List ( Evergreen.V156.Slack.Channel, List Evergreen.V156.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Result Effect.Http.Error Evergreen.V156.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) Evergreen.V156.Discord.UserAuth (Result Evergreen.V156.Discord.HttpError Evergreen.V156.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Result Evergreen.V156.Discord.HttpError Evergreen.V156.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
        (Result
            Evergreen.V156.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId
                , members : List (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
                }
            , List
                ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId
                , { guild : Evergreen.V156.Discord.GatewayGuild
                  , channels : List Evergreen.V156.Discord.Channel
                  , icon : Maybe Evergreen.V156.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V156.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.AttachmentId, Evergreen.V156.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V156.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V156.Discord.Id Evergreen.V156.Discord.AttachmentId, Evergreen.V156.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V156.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V156.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V156.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V156.FileStatus.UploadResponse )))
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) (Result Evergreen.V156.Discord.HttpError (List Evergreen.V156.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId) (Result Evergreen.V156.Discord.HttpError (List Evergreen.V156.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) Evergreen.V156.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V156.RichText.EmbedData )
    | GotDmMessageEmbed Evergreen.V156.DmChannel.DmChannelId Evergreen.V156.Id.ThreadRouteWithMessage ( Int, Result Effect.Http.Error Evergreen.V156.RichText.EmbedData )


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
    | AdminToFrontend Evergreen.V156.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V156.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V156.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V156.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V156.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V156.ImageEditor.ToFrontend
