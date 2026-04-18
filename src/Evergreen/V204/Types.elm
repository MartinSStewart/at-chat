module Evergreen.V204.Types exposing (..)

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
import Evergreen.V204.AiChat
import Evergreen.V204.ChannelName
import Evergreen.V204.Coord
import Evergreen.V204.CssPixels
import Evergreen.V204.Discord
import Evergreen.V204.DiscordAttachmentId
import Evergreen.V204.DiscordUserData
import Evergreen.V204.DmChannel
import Evergreen.V204.Editable
import Evergreen.V204.EmailAddress
import Evergreen.V204.Embed
import Evergreen.V204.Emoji
import Evergreen.V204.FileStatus
import Evergreen.V204.GuildName
import Evergreen.V204.Id
import Evergreen.V204.ImageEditor
import Evergreen.V204.Local
import Evergreen.V204.LocalState
import Evergreen.V204.Log
import Evergreen.V204.LoginForm
import Evergreen.V204.MembersAndOwner
import Evergreen.V204.Message
import Evergreen.V204.MessageInput
import Evergreen.V204.MessageView
import Evergreen.V204.NonemptyDict
import Evergreen.V204.NonemptySet
import Evergreen.V204.OneToOne
import Evergreen.V204.Pages.Admin
import Evergreen.V204.Pagination
import Evergreen.V204.PersonName
import Evergreen.V204.Ports
import Evergreen.V204.Postmark
import Evergreen.V204.Range
import Evergreen.V204.RichText
import Evergreen.V204.Route
import Evergreen.V204.SecretId
import Evergreen.V204.SessionIdHash
import Evergreen.V204.Slack
import Evergreen.V204.Sticker
import Evergreen.V204.TextEditor
import Evergreen.V204.ToBackendLog
import Evergreen.V204.Touch
import Evergreen.V204.TwoFactorAuthentication
import Evergreen.V204.Ui.Anim
import Evergreen.V204.Untrusted
import Evergreen.V204.User
import Evergreen.V204.UserAgent
import Evergreen.V204.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V204.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V204.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.LocalState.DiscordFrontendGuild
    , user : Evergreen.V204.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V204.SessionIdHash.SessionIdHash Evergreen.V204.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V204.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V204.Route.Route
    , windowSize : Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V204.Ports.NotificationPermission
    , pwaStatus : Evergreen.V204.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V204.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V204.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V204.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))) Evergreen.V204.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V204.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))) Evergreen.V204.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V204.GuildName.GuildName (Evergreen.V204.UserSession.ToBeFilledInByBackend (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V204.Id.GuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))) (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V204.Id.DiscordGuildOrDmId_DmData (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V204.UserSession.SetViewing
    | Local_SetName Evergreen.V204.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V204.Id.GuildOrDmId (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V204.Id.GuildOrDmId (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V204.Id.DiscordGuildOrDmId (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V204.Id.DiscordGuildOrDmId (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.Message.Message Evergreen.V204.Id.ThreadMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V204.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V204.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V204.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V204.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V204.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V204.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Effect.Time.Posix Evergreen.V204.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))) Evergreen.V204.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V204.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))) Evergreen.V204.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V204.LocalState.JoinGuildError
            { guildId : Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId
            , guild : Evergreen.V204.LocalState.FrontendGuild
            , owner : Evergreen.V204.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.GuildOrDmId Evergreen.V204.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.GuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.GuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.GuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))) (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V204.Id.DiscordGuildOrDmId_DmData (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V204.SessionIdHash.SessionIdHash Evergreen.V204.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V204.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V204.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V204.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.ChannelName.ChannelName (Evergreen.V204.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)
        (Evergreen.V204.NonemptyDict.NonemptyDict
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Maybe (Evergreen.V204.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V204.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V204.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V204.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V204.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V204.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V204.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (Evergreen.V204.Discord.OptionalData String) (Evergreen.V204.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
        (Evergreen.V204.MembersAndOwner.MembersAndOwner
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V204.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V204.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V204.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V204.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels) (Maybe Evergreen.V204.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId) (Evergreen.V204.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V204.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V204.Local.Local LocalMsg Evergreen.V204.LocalState.LocalState
    , admin : Evergreen.V204.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId, Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V204.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V204.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V204.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.NonemptyDict.NonemptyDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V204.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V204.TextEditor.Model
    , profilePictureEditor : Evergreen.V204.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V204.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V204.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V204.Range.Range
                , direction : Evergreen.V204.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V204.NonemptyDict.NonemptyDict Int Evergreen.V204.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V204.NonemptyDict.NonemptyDict Int Evergreen.V204.Touch.Touch
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
    | AdminToFrontend Evergreen.V204.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V204.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V204.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V204.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V204.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V204.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V204.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V204.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V204.Ports.NotificationPermission
    , pwaStatus : Evergreen.V204.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V204.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V204.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V204.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V204.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V204.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V204.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V204.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId, Evergreen.V204.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V204.DmChannel.DmChannelId, Evergreen.V204.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId, Evergreen.V204.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId, Evergreen.V204.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V204.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V204.NonemptyDict.NonemptyDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V204.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V204.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V204.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V204.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V204.DmChannel.DmChannelId Evergreen.V204.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) Evergreen.V204.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Slack.Id Evergreen.V204.Slack.ChannelId) Evergreen.V204.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V204.OneToOne.OneToOne String (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    , slackUsers : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Slack.Id Evergreen.V204.Slack.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
    , slackServers : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Slack.Id Evergreen.V204.Slack.TeamId) (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    , slackToken : Maybe Evergreen.V204.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V204.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V204.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V204.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V204.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId, Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V204.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V204.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V204.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V204.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.LocalState.LoadingDiscordChannel (List Evergreen.V204.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V204.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId) Evergreen.V204.Sticker.StickerData
    , discordStickers : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Discord.Id Evergreen.V204.Discord.StickerId) (Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V204.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V204.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V204.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V204.Route.Route
    | SelectedFilesToAttach ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V204.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V204.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V204.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V204.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V204.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V204.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V204.NonemptyDict.NonemptyDict Int Evergreen.V204.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V204.NonemptyDict.NonemptyDict Int Evergreen.V204.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V204.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V204.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V204.Editable.Msg Evergreen.V204.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V204.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V204.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
        { fileId : Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute )
        { fileId : Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V204.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V204.Id.AnyGuildOrDmId, Evergreen.V204.Id.ThreadRoute ) (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRouteWithMessage Evergreen.V204.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V204.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V204.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) Evergreen.V204.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) Evergreen.V204.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V204.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V204.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId
        , otherUserId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V204.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRoute Evergreen.V204.MessageInput.Msg
    | MessageInputMsg Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRoute Evergreen.V204.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V204.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V204.Range.Range, Evergreen.V204.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V204.Range.Range, Evergreen.V204.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V204.Id.AnyGuildOrDmId Evergreen.V204.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V204.Id.Id Evergreen.V204.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V204.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V204.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V204.Untrusted.Untrusted Evergreen.V204.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V204.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V204.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V204.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V204.PersonName.PersonName Evergreen.V204.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V204.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V204.Slack.OAuthCode Evergreen.V204.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V204.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V204.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V204.Id.Id Evergreen.V204.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V204.EmailAddress.EmailAddress (Result Evergreen.V204.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V204.EmailAddress.EmailAddress (Result Evergreen.V204.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Evergreen.V204.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V204.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMaybeMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Result Evergreen.V204.Discord.HttpError Evergreen.V204.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V204.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Result Evergreen.V204.Discord.HttpError Evergreen.V204.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Result Evergreen.V204.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Result Evergreen.V204.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Result Evergreen.V204.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Result Evergreen.V204.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji (Result Evergreen.V204.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji (Result Evergreen.V204.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji (Result Evergreen.V204.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) Evergreen.V204.Emoji.Emoji (Result Evergreen.V204.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V204.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V204.Discord.HttpError (List ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId, Maybe Evergreen.V204.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V204.Slack.CurrentUser
            , team : Evergreen.V204.Slack.Team
            , users : List Evergreen.V204.Slack.User
            , channels : List ( Evergreen.V204.Slack.Channel, List Evergreen.V204.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Result Effect.Http.Error Evergreen.V204.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) Evergreen.V204.Discord.UserAuth (Result Evergreen.V204.Discord.HttpError Evergreen.V204.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Result Evergreen.V204.Discord.HttpError Evergreen.V204.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
        (Result
            Evergreen.V204.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId
                , members : List (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
                }
            , List
                ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId
                , { guild : Evergreen.V204.Discord.GatewayGuild
                  , channels : List Evergreen.V204.Discord.Channel
                  , icon : Maybe Evergreen.V204.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V204.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.AttachmentId, Evergreen.V204.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V204.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V204.Discord.Id Evergreen.V204.Discord.AttachmentId, Evergreen.V204.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V204.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V204.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V204.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V204.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) (Result Evergreen.V204.Discord.HttpError (List Evergreen.V204.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Result Evergreen.V204.Discord.HttpError (List Evergreen.V204.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V204.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V204.DmChannel.DmChannelId Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V204.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) Evergreen.V204.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V204.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V204.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
        (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V204.Discord.HttpError
            { guild : Evergreen.V204.Discord.GatewayGuild
            , channels : List Evergreen.V204.Discord.Channel
            , icon : Maybe Evergreen.V204.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId) (Result Evergreen.V204.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V204.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (List ( Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId, Result Effect.Http.Error Evergreen.V204.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V204.Id.Id Evergreen.V204.Id.StickerId, Result Effect.Http.Error Evergreen.V204.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V204.Discord.HttpError (List Evergreen.V204.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
