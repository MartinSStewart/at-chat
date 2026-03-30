module Evergreen.V181.Types exposing (..)

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
import Evergreen.V181.AiChat
import Evergreen.V181.ChannelName
import Evergreen.V181.Coord
import Evergreen.V181.CssPixels
import Evergreen.V181.Discord
import Evergreen.V181.DiscordAttachmentId
import Evergreen.V181.DiscordUserData
import Evergreen.V181.DmChannel
import Evergreen.V181.Editable
import Evergreen.V181.EmailAddress
import Evergreen.V181.Embed
import Evergreen.V181.Emoji
import Evergreen.V181.FileStatus
import Evergreen.V181.GuildName
import Evergreen.V181.Id
import Evergreen.V181.ImageEditor
import Evergreen.V181.Local
import Evergreen.V181.LocalState
import Evergreen.V181.Log
import Evergreen.V181.LoginForm
import Evergreen.V181.MembersAndOwner
import Evergreen.V181.Message
import Evergreen.V181.MessageInput
import Evergreen.V181.MessageView
import Evergreen.V181.MyUi
import Evergreen.V181.NonemptyDict
import Evergreen.V181.NonemptySet
import Evergreen.V181.OneToOne
import Evergreen.V181.Pages.Admin
import Evergreen.V181.Pagination
import Evergreen.V181.PersonName
import Evergreen.V181.Ports
import Evergreen.V181.Postmark
import Evergreen.V181.RichText
import Evergreen.V181.Route
import Evergreen.V181.SecretId
import Evergreen.V181.SessionIdHash
import Evergreen.V181.Slack
import Evergreen.V181.TextEditor
import Evergreen.V181.Touch
import Evergreen.V181.TwoFactorAuthentication
import Evergreen.V181.Ui.Anim
import Evergreen.V181.Untrusted
import Evergreen.V181.User
import Evergreen.V181.UserAgent
import Evergreen.V181.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V181.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V181.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.LocalState.DiscordFrontendGuild
    , user : Evergreen.V181.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V181.SessionIdHash.SessionIdHash Evergreen.V181.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V181.TextEditor.LocalState
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V181.Route.Route
    , windowSize : Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V181.Ports.NotificationPermission
    , pwaStatus : Evergreen.V181.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V181.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V181.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V181.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))) Evergreen.V181.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V181.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))) Evergreen.V181.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V181.GuildName.GuildName (Evergreen.V181.UserSession.ToBeFilledInByBackend (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V181.Id.GuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))) (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V181.Id.DiscordGuildOrDmId_DmData (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V181.UserSession.SetViewing
    | Local_SetName Evergreen.V181.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V181.Id.GuildOrDmId (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V181.Id.GuildOrDmId (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V181.Id.DiscordGuildOrDmId (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V181.Id.DiscordGuildOrDmId (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.Message.Message Evergreen.V181.Id.ThreadMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V181.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V181.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V181.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V181.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V181.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V181.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Effect.Time.Posix Evergreen.V181.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))) Evergreen.V181.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V181.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))) Evergreen.V181.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V181.LocalState.JoinGuildError
            { guildId : Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId
            , guild : Evergreen.V181.LocalState.FrontendGuild
            , owner : Evergreen.V181.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.GuildOrDmId Evergreen.V181.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.GuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.GuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.GuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))) (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V181.Id.DiscordGuildOrDmId_DmData (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V181.SessionIdHash.SessionIdHash Evergreen.V181.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V181.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V181.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V181.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.ChannelName.ChannelName (Evergreen.V181.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId)
        (Evergreen.V181.NonemptyDict.NonemptyDict
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Maybe (Evergreen.V181.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V181.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V181.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V181.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V181.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V181.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V181.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (Evergreen.V181.Discord.OptionalData String) (Evergreen.V181.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
        (Evergreen.V181.MembersAndOwner.MembersAndOwner
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )


type LocalMsg
    = LocalChange (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V181.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V181.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V181.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V181.MyUi.Range)
    | EmojiSelectorForEditMessage (Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels) (Maybe Evergreen.V181.MyUi.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId) (Evergreen.V181.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V181.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V181.Local.Local LocalMsg Evergreen.V181.LocalState.LocalState
    , admin : Evergreen.V181.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId, Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V181.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V181.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V181.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.NonemptyDict.NonemptyDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V181.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V181.TextEditor.Model
    , profilePictureEditor : Evergreen.V181.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V181.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V181.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V181.MyUi.Range
                , direction : Evergreen.V181.MyUi.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V181.NonemptyDict.NonemptyDict Int Evergreen.V181.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V181.NonemptyDict.NonemptyDict Int Evergreen.V181.Touch.Touch
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
    | AdminToFrontend Evergreen.V181.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V181.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V181.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V181.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V181.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V181.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V181.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V181.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V181.Ports.NotificationPermission
    , pwaStatus : Evergreen.V181.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V181.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V181.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V181.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V181.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V181.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V181.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V181.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId, Evergreen.V181.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V181.DmChannel.DmChannelId, Evergreen.V181.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId, Evergreen.V181.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId, Evergreen.V181.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V181.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V181.NonemptyDict.NonemptyDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V181.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V181.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V181.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V181.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.LocalState.BackendGuild
    , backendInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V181.DmChannel.DmChannelId Evergreen.V181.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) Evergreen.V181.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Slack.Id Evergreen.V181.Slack.ChannelId) Evergreen.V181.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V181.OneToOne.OneToOne String (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    , slackUsers : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Slack.Id Evergreen.V181.Slack.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    , slackServers : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Slack.Id Evergreen.V181.Slack.TeamId) (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    , slackToken : Maybe Evergreen.V181.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V181.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V181.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V181.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V181.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId, Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V181.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V181.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V181.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V181.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.LocalState.LoadingDiscordChannel (List Evergreen.V181.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V181.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V181.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V181.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V181.Route.Route
    | SelectedFilesToAttach ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V181.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Coord.Coord Evergreen.V181.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V181.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V181.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V181.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V181.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V181.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V181.NonemptyDict.NonemptyDict Int Evergreen.V181.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V181.NonemptyDict.NonemptyDict Int Evergreen.V181.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V181.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V181.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V181.Editable.Msg Evergreen.V181.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V181.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V181.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V181.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V181.Id.AnyGuildOrDmId, Evergreen.V181.Id.ThreadRoute ) (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRouteWithMessage Evergreen.V181.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V181.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V181.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) Evergreen.V181.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) Evergreen.V181.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V181.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V181.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId
        , otherUserId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V181.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRoute Evergreen.V181.MessageInput.Msg
    | MessageInputMsg Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRoute Evergreen.V181.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V181.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V181.MyUi.Range, Evergreen.V181.MyUi.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V181.MyUi.Range, Evergreen.V181.MyUi.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V181.Id.AnyGuildOrDmId Evergreen.V181.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V181.Id.Id Evergreen.V181.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V181.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V181.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V181.Untrusted.Untrusted Evergreen.V181.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V181.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V181.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V181.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V181.PersonName.PersonName Evergreen.V181.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V181.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V181.Slack.OAuthCode Evergreen.V181.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V181.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V181.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V181.Id.Id Evergreen.V181.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V181.EmailAddress.EmailAddress (Result Evergreen.V181.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V181.EmailAddress.EmailAddress (Result Evergreen.V181.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Evergreen.V181.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V181.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMaybeMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Result Evergreen.V181.Discord.HttpError Evergreen.V181.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V181.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Result Evergreen.V181.Discord.HttpError Evergreen.V181.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Result Evergreen.V181.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Result Evergreen.V181.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Result Evergreen.V181.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Result Evergreen.V181.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji (Result Evergreen.V181.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji (Result Evergreen.V181.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji (Result Evergreen.V181.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) Evergreen.V181.Emoji.Emoji (Result Evergreen.V181.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V181.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V181.Discord.HttpError (List ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId, Maybe Evergreen.V181.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V181.Slack.CurrentUser
            , team : Evergreen.V181.Slack.Team
            , users : List Evergreen.V181.Slack.User
            , channels : List ( Evergreen.V181.Slack.Channel, List Evergreen.V181.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Result Effect.Http.Error Evergreen.V181.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.Discord.UserAuth (Result Evergreen.V181.Discord.HttpError Evergreen.V181.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Result Evergreen.V181.Discord.HttpError Evergreen.V181.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
        (Result
            Evergreen.V181.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId
                , members : List (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
                }
            , List
                ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId
                , { guild : Evergreen.V181.Discord.GatewayGuild
                  , channels : List Evergreen.V181.Discord.Channel
                  , icon : Maybe Evergreen.V181.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V181.Discord.Message (List (Result Effect.Http.Error ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.AttachmentId, Evergreen.V181.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V181.Discord.UserMessageUpdate (List (Result Effect.Http.Error ( Evergreen.V181.Discord.Id Evergreen.V181.Discord.AttachmentId, Evergreen.V181.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V181.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V181.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V181.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V181.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) (Result Evergreen.V181.Discord.HttpError (List Evergreen.V181.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Result Evergreen.V181.Discord.HttpError (List Evergreen.V181.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V181.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V181.DmChannel.DmChannelId Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V181.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) Evergreen.V181.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V181.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V181.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
        (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V181.Discord.HttpError
            { guild : Evergreen.V181.Discord.GatewayGuild
            , channels : List Evergreen.V181.Discord.Channel
            , icon : Maybe Evergreen.V181.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId) (Result Evergreen.V181.Discord.HttpError ()) Effect.Time.Posix
