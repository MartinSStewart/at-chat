module Evergreen.V199.Types exposing (..)

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
import Evergreen.V199.AiChat
import Evergreen.V199.ChannelName
import Evergreen.V199.Coord
import Evergreen.V199.CssPixels
import Evergreen.V199.Discord
import Evergreen.V199.DiscordAttachmentId
import Evergreen.V199.DiscordUserData
import Evergreen.V199.DmChannel
import Evergreen.V199.Editable
import Evergreen.V199.EmailAddress
import Evergreen.V199.Embed
import Evergreen.V199.Emoji
import Evergreen.V199.FileStatus
import Evergreen.V199.GuildName
import Evergreen.V199.Id
import Evergreen.V199.ImageEditor
import Evergreen.V199.Local
import Evergreen.V199.LocalState
import Evergreen.V199.Log
import Evergreen.V199.LoginForm
import Evergreen.V199.MembersAndOwner
import Evergreen.V199.Message
import Evergreen.V199.MessageInput
import Evergreen.V199.MessageView
import Evergreen.V199.NonemptyDict
import Evergreen.V199.NonemptySet
import Evergreen.V199.OneToOne
import Evergreen.V199.Pages.Admin
import Evergreen.V199.Pagination
import Evergreen.V199.PersonName
import Evergreen.V199.Ports
import Evergreen.V199.Postmark
import Evergreen.V199.Range
import Evergreen.V199.RichText
import Evergreen.V199.Route
import Evergreen.V199.SecretId
import Evergreen.V199.SessionIdHash
import Evergreen.V199.Slack
import Evergreen.V199.Sticker
import Evergreen.V199.TextEditor
import Evergreen.V199.ToBackendLog
import Evergreen.V199.Touch
import Evergreen.V199.TwoFactorAuthentication
import Evergreen.V199.Ui.Anim
import Evergreen.V199.Untrusted
import Evergreen.V199.User
import Evergreen.V199.UserAgent
import Evergreen.V199.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V199.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V199.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.LocalState.DiscordFrontendGuild
    , user : Evergreen.V199.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V199.SessionIdHash.SessionIdHash Evergreen.V199.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V199.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V199.Route.Route
    , windowSize : Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V199.Ports.NotificationPermission
    , pwaStatus : Evergreen.V199.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V199.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V199.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V199.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))) Evergreen.V199.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V199.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))) Evergreen.V199.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V199.GuildName.GuildName (Evergreen.V199.UserSession.ToBeFilledInByBackend (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V199.Id.GuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))) (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V199.Id.DiscordGuildOrDmId_DmData (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V199.UserSession.SetViewing
    | Local_SetName Evergreen.V199.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V199.Id.GuildOrDmId (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V199.Id.GuildOrDmId (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V199.Id.DiscordGuildOrDmId (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V199.Id.DiscordGuildOrDmId (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.Message.Message Evergreen.V199.Id.ThreadMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V199.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V199.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V199.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V199.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V199.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V199.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Effect.Time.Posix Evergreen.V199.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))) Evergreen.V199.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V199.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))) Evergreen.V199.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V199.LocalState.JoinGuildError
            { guildId : Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId
            , guild : Evergreen.V199.LocalState.FrontendGuild
            , owner : Evergreen.V199.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.GuildOrDmId Evergreen.V199.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.GuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.GuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.GuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))) (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V199.Id.DiscordGuildOrDmId_DmData (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V199.SessionIdHash.SessionIdHash Evergreen.V199.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V199.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V199.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V199.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.ChannelName.ChannelName (Evergreen.V199.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)
        (Evergreen.V199.NonemptyDict.NonemptyDict
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Maybe (Evergreen.V199.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V199.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V199.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V199.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V199.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V199.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V199.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (Evergreen.V199.Discord.OptionalData String) (Evergreen.V199.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
        (Evergreen.V199.MembersAndOwner.MembersAndOwner
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V199.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V199.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V199.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V199.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels) (Maybe Evergreen.V199.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId) (Evergreen.V199.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V199.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V199.Local.Local LocalMsg Evergreen.V199.LocalState.LocalState
    , admin : Evergreen.V199.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId, Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V199.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V199.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V199.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.NonemptyDict.NonemptyDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V199.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V199.TextEditor.Model
    , profilePictureEditor : Evergreen.V199.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V199.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V199.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V199.Range.Range
                , direction : Evergreen.V199.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V199.NonemptyDict.NonemptyDict Int Evergreen.V199.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V199.NonemptyDict.NonemptyDict Int Evergreen.V199.Touch.Touch
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
    | AdminToFrontend Evergreen.V199.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V199.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V199.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V199.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V199.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V199.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V199.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V199.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V199.Ports.NotificationPermission
    , pwaStatus : Evergreen.V199.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V199.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V199.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V199.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V199.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V199.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V199.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V199.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId, Evergreen.V199.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V199.DmChannel.DmChannelId, Evergreen.V199.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId, Evergreen.V199.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId, Evergreen.V199.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V199.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V199.NonemptyDict.NonemptyDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V199.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V199.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V199.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V199.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V199.DmChannel.DmChannelId Evergreen.V199.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) Evergreen.V199.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Slack.Id Evergreen.V199.Slack.ChannelId) Evergreen.V199.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V199.OneToOne.OneToOne String (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    , slackUsers : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Slack.Id Evergreen.V199.Slack.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
    , slackServers : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Slack.Id Evergreen.V199.Slack.TeamId) (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    , slackToken : Maybe Evergreen.V199.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V199.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V199.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V199.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V199.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId, Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V199.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V199.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V199.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V199.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.LocalState.LoadingDiscordChannel (List Evergreen.V199.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V199.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId) Evergreen.V199.Sticker.StickerData
    , discordStickers : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Discord.Id Evergreen.V199.Discord.StickerId) (Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V199.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V199.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V199.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V199.Route.Route
    | SelectedFilesToAttach ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V199.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V199.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V199.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V199.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V199.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V199.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V199.NonemptyDict.NonemptyDict Int Evergreen.V199.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V199.NonemptyDict.NonemptyDict Int Evergreen.V199.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V199.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V199.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V199.Editable.Msg Evergreen.V199.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V199.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V199.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
        { fileId : Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute )
        { fileId : Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V199.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V199.Id.AnyGuildOrDmId, Evergreen.V199.Id.ThreadRoute ) (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRouteWithMessage Evergreen.V199.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V199.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V199.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) Evergreen.V199.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) Evergreen.V199.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V199.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V199.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId
        , otherUserId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V199.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRoute Evergreen.V199.MessageInput.Msg
    | MessageInputMsg Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRoute Evergreen.V199.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V199.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V199.Range.Range, Evergreen.V199.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V199.Range.Range, Evergreen.V199.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V199.Id.AnyGuildOrDmId Evergreen.V199.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V199.Id.Id Evergreen.V199.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V199.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V199.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V199.Untrusted.Untrusted Evergreen.V199.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V199.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V199.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V199.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V199.PersonName.PersonName Evergreen.V199.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V199.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V199.Slack.OAuthCode Evergreen.V199.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V199.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V199.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V199.Id.Id Evergreen.V199.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V199.EmailAddress.EmailAddress (Result Evergreen.V199.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V199.EmailAddress.EmailAddress (Result Evergreen.V199.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Evergreen.V199.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V199.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMaybeMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Result Evergreen.V199.Discord.HttpError Evergreen.V199.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V199.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Result Evergreen.V199.Discord.HttpError Evergreen.V199.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Result Evergreen.V199.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Result Evergreen.V199.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Result Evergreen.V199.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Result Evergreen.V199.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji (Result Evergreen.V199.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji (Result Evergreen.V199.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji (Result Evergreen.V199.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) Evergreen.V199.Emoji.Emoji (Result Evergreen.V199.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V199.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V199.Discord.HttpError (List ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId, Maybe Evergreen.V199.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V199.Slack.CurrentUser
            , team : Evergreen.V199.Slack.Team
            , users : List Evergreen.V199.Slack.User
            , channels : List ( Evergreen.V199.Slack.Channel, List Evergreen.V199.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Result Effect.Http.Error Evergreen.V199.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) Evergreen.V199.Discord.UserAuth (Result Evergreen.V199.Discord.HttpError Evergreen.V199.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Result Evergreen.V199.Discord.HttpError Evergreen.V199.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
        (Result
            Evergreen.V199.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId
                , members : List (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
                }
            , List
                ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId
                , { guild : Evergreen.V199.Discord.GatewayGuild
                  , channels : List Evergreen.V199.Discord.Channel
                  , icon : Maybe Evergreen.V199.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V199.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.AttachmentId, Evergreen.V199.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V199.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V199.Discord.Id Evergreen.V199.Discord.AttachmentId, Evergreen.V199.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V199.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V199.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V199.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V199.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) (Result Evergreen.V199.Discord.HttpError (List Evergreen.V199.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Result Evergreen.V199.Discord.HttpError (List Evergreen.V199.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V199.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V199.DmChannel.DmChannelId Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V199.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) Evergreen.V199.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V199.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V199.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
        (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V199.Discord.HttpError
            { guild : Evergreen.V199.Discord.GatewayGuild
            , channels : List Evergreen.V199.Discord.Channel
            , icon : Maybe Evergreen.V199.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId) (Result Evergreen.V199.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V199.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (List ( Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId, Result Effect.Http.Error Evergreen.V199.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V199.Id.Id Evergreen.V199.Id.StickerId, Result Effect.Http.Error Evergreen.V199.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V199.Discord.HttpError (List Evergreen.V199.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
