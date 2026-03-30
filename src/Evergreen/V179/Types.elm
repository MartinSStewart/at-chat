module Evergreen.V179.Types exposing (..)

import Array
import Browser
import Bytes
import Duration
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.Websocket
import Evergreen.V179.AiChat
import Evergreen.V179.ChannelName
import Evergreen.V179.Coord
import Evergreen.V179.CssPixels
import Evergreen.V179.Discord
import Evergreen.V179.DiscordAttachmentId
import Evergreen.V179.DiscordUserData
import Evergreen.V179.DmChannel
import Evergreen.V179.Editable
import Evergreen.V179.EmailAddress
import Evergreen.V179.Embed
import Evergreen.V179.Emoji
import Evergreen.V179.FileStatus
import Evergreen.V179.GuildName
import Evergreen.V179.Id
import Evergreen.V179.ImageEditor
import Evergreen.V179.Local
import Evergreen.V179.LocalState
import Evergreen.V179.Log
import Evergreen.V179.LoginForm
import Evergreen.V179.MembersAndOwner
import Evergreen.V179.Message
import Evergreen.V179.MessageInput
import Evergreen.V179.MessageView
import Evergreen.V179.MyUi
import Evergreen.V179.NonemptyDict
import Evergreen.V179.NonemptySet
import Evergreen.V179.OneToOne
import Evergreen.V179.Pages.Admin
import Evergreen.V179.Pagination
import Evergreen.V179.PersonName
import Evergreen.V179.Ports
import Evergreen.V179.Postmark
import Evergreen.V179.RichText
import Evergreen.V179.Route
import Evergreen.V179.SecretId
import Evergreen.V179.SessionIdHash
import Evergreen.V179.Slack
import Evergreen.V179.TextEditor
import Evergreen.V179.Touch
import Evergreen.V179.TwoFactorAuthentication
import Evergreen.V179.Ui.Anim
import Evergreen.V179.Untrusted
import Evergreen.V179.User
import Evergreen.V179.UserAgent
import Evergreen.V179.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V179.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V179.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.LocalState.DiscordFrontendGuild
    , user : Evergreen.V179.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V179.SessionIdHash.SessionIdHash Evergreen.V179.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V179.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V179.Route.Route
    , windowSize : Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V179.Ports.NotificationPermission
    , pwaStatus : Evergreen.V179.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V179.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V179.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V179.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))) Evergreen.V179.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V179.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))) Evergreen.V179.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V179.GuildName.GuildName (Evergreen.V179.UserSession.ToBeFilledInByBackend (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V179.Id.GuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))) (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V179.Id.DiscordGuildOrDmId_DmData (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V179.UserSession.SetViewing
    | Local_SetName Evergreen.V179.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V179.Id.GuildOrDmId (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V179.Id.GuildOrDmId (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V179.Id.DiscordGuildOrDmId (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V179.Id.DiscordGuildOrDmId (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.Message.Message Evergreen.V179.Id.ThreadMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V179.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V179.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V179.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V179.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V179.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V179.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Effect.Time.Posix Evergreen.V179.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))) Evergreen.V179.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V179.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))) Evergreen.V179.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V179.LocalState.JoinGuildError
            { guildId : Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId
            , guild : Evergreen.V179.LocalState.FrontendGuild
            , owner : Evergreen.V179.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.GuildOrDmId Evergreen.V179.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.GuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.GuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.GuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))) (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V179.Id.DiscordGuildOrDmId_DmData (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V179.SessionIdHash.SessionIdHash Evergreen.V179.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V179.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V179.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V179.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.ChannelName.ChannelName (Evergreen.V179.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId)
        (Evergreen.V179.NonemptyDict.NonemptyDict
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Maybe (Evergreen.V179.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V179.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V179.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V179.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V179.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V179.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V179.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (Evergreen.V179.Discord.OptionalData String) (Evergreen.V179.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
        (Evergreen.V179.MembersAndOwner.MembersAndOwner
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V179.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V179.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V179.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V179.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels) (Maybe Evergreen.V179.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId) (Evergreen.V179.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V179.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V179.Local.Local LocalMsg Evergreen.V179.LocalState.LocalState
    , admin : Evergreen.V179.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId, Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V179.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V179.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V179.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.NonemptyDict.NonemptyDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V179.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V179.TextEditor.Model
    , profilePictureEditor : Evergreen.V179.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V179.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V179.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V179.NonemptyDict.NonemptyDict Int Evergreen.V179.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V179.NonemptyDict.NonemptyDict Int Evergreen.V179.Touch.Touch
        }


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
    | AdminToFrontend Evergreen.V179.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V179.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V179.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V179.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V179.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V179.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V179.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V179.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V179.Ports.NotificationPermission
    , pwaStatus : Evergreen.V179.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V179.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V179.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V179.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V179.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V179.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V179.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V179.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId, Evergreen.V179.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V179.DmChannel.DmChannelId, Evergreen.V179.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId, Evergreen.V179.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId, Evergreen.V179.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V179.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V179.NonemptyDict.NonemptyDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V179.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V179.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V179.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V179.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V179.DmChannel.DmChannelId Evergreen.V179.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) Evergreen.V179.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Slack.Id Evergreen.V179.Slack.ChannelId) Evergreen.V179.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V179.OneToOne.OneToOne String (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    , slackUsers : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Slack.Id Evergreen.V179.Slack.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
    , slackServers : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Slack.Id Evergreen.V179.Slack.TeamId) (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    , slackToken : Maybe Evergreen.V179.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V179.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V179.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V179.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V179.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId, Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V179.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V179.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V179.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V179.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.LocalState.LoadingDiscordChannel (List Evergreen.V179.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V179.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V179.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V179.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V179.Route.Route
    | SelectedFilesToAttach ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V179.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | TextInputGotFocus Effect.Browser.Dom.HtmlId
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V179.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V179.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V179.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V179.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V179.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V179.NonemptyDict.NonemptyDict Int Evergreen.V179.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V179.NonemptyDict.NonemptyDict Int Evergreen.V179.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V179.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V179.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V179.Editable.Msg Evergreen.V179.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V179.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V179.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V179.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V179.Id.AnyGuildOrDmId, Evergreen.V179.Id.ThreadRoute ) (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRouteWithMessage Evergreen.V179.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V179.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V179.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) Evergreen.V179.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) Evergreen.V179.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V179.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V179.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId
        , otherUserId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V179.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRoute Evergreen.V179.MessageInput.Msg
    | MessageInputMsg Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRoute Evergreen.V179.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V179.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V179.Id.AnyGuildOrDmId Evergreen.V179.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V179.Id.Id Evergreen.V179.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V179.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V179.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V179.Untrusted.Untrusted Evergreen.V179.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V179.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V179.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V179.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V179.PersonName.PersonName Evergreen.V179.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V179.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V179.Slack.OAuthCode Evergreen.V179.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V179.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V179.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V179.Id.Id Evergreen.V179.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V179.EmailAddress.EmailAddress (Result Evergreen.V179.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V179.EmailAddress.EmailAddress (Result Evergreen.V179.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Evergreen.V179.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V179.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMaybeMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Result Evergreen.V179.Discord.HttpError Evergreen.V179.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V179.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Result Evergreen.V179.Discord.HttpError Evergreen.V179.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Result Evergreen.V179.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Result Evergreen.V179.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Result Evergreen.V179.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Result Evergreen.V179.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji (Result Evergreen.V179.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji (Result Evergreen.V179.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji (Result Evergreen.V179.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) Evergreen.V179.Emoji.Emoji (Result Evergreen.V179.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V179.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V179.Discord.HttpError (List ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId, Maybe Evergreen.V179.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V179.Slack.CurrentUser
            , team : Evergreen.V179.Slack.Team
            , users : List Evergreen.V179.Slack.User
            , channels : List ( Evergreen.V179.Slack.Channel, List Evergreen.V179.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Result Effect.Http.Error Evergreen.V179.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) Evergreen.V179.Discord.UserAuth (Result Evergreen.V179.Discord.HttpError Evergreen.V179.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Result Evergreen.V179.Discord.HttpError Evergreen.V179.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
        (Result
            Evergreen.V179.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId
                , members : List (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
                }
            , List
                ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId
                , { guild : Evergreen.V179.Discord.GatewayGuild
                  , channels : List Evergreen.V179.Discord.Channel
                  , icon : Maybe Evergreen.V179.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V179.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.AttachmentId, Evergreen.V179.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V179.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V179.Discord.Id Evergreen.V179.Discord.AttachmentId, Evergreen.V179.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V179.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V179.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V179.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V179.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) (Result Evergreen.V179.Discord.HttpError (List Evergreen.V179.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Result Evergreen.V179.Discord.HttpError (List Evergreen.V179.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V179.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V179.DmChannel.DmChannelId Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V179.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) Evergreen.V179.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V179.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V179.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
        (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V179.Discord.HttpError
            { guild : Evergreen.V179.Discord.GatewayGuild
            , channels : List Evergreen.V179.Discord.Channel
            , icon : Maybe Evergreen.V179.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId) (Result Evergreen.V179.Discord.HttpError ()) Effect.Time.Posix
