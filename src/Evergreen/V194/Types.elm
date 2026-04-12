module Evergreen.V194.Types exposing (..)

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
import Evergreen.V194.AiChat
import Evergreen.V194.ChannelName
import Evergreen.V194.Coord
import Evergreen.V194.CssPixels
import Evergreen.V194.Discord
import Evergreen.V194.DiscordAttachmentId
import Evergreen.V194.DiscordUserData
import Evergreen.V194.DmChannel
import Evergreen.V194.Editable
import Evergreen.V194.EmailAddress
import Evergreen.V194.Embed
import Evergreen.V194.Emoji
import Evergreen.V194.FileStatus
import Evergreen.V194.GuildName
import Evergreen.V194.Id
import Evergreen.V194.ImageEditor
import Evergreen.V194.Local
import Evergreen.V194.LocalState
import Evergreen.V194.Log
import Evergreen.V194.LoginForm
import Evergreen.V194.MembersAndOwner
import Evergreen.V194.Message
import Evergreen.V194.MessageInput
import Evergreen.V194.MessageView
import Evergreen.V194.NonemptyDict
import Evergreen.V194.NonemptySet
import Evergreen.V194.OneToOne
import Evergreen.V194.Pages.Admin
import Evergreen.V194.Pagination
import Evergreen.V194.PersonName
import Evergreen.V194.Ports
import Evergreen.V194.Postmark
import Evergreen.V194.Range
import Evergreen.V194.RichText
import Evergreen.V194.Route
import Evergreen.V194.SecretId
import Evergreen.V194.SessionIdHash
import Evergreen.V194.Slack
import Evergreen.V194.Sticker
import Evergreen.V194.TextEditor
import Evergreen.V194.ToBackendLog
import Evergreen.V194.Touch
import Evergreen.V194.TwoFactorAuthentication
import Evergreen.V194.Ui.Anim
import Evergreen.V194.Untrusted
import Evergreen.V194.User
import Evergreen.V194.UserAgent
import Evergreen.V194.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V194.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V194.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.LocalState.DiscordFrontendGuild
    , user : Evergreen.V194.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V194.SessionIdHash.SessionIdHash Evergreen.V194.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V194.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V194.Route.Route
    , windowSize : Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V194.Ports.NotificationPermission
    , pwaStatus : Evergreen.V194.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V194.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V194.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V194.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))) Evergreen.V194.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V194.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))) Evergreen.V194.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V194.GuildName.GuildName (Evergreen.V194.UserSession.ToBeFilledInByBackend (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V194.Id.GuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))) (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V194.Id.DiscordGuildOrDmId_DmData (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V194.UserSession.SetViewing
    | Local_SetName Evergreen.V194.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V194.Id.GuildOrDmId (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V194.Id.GuildOrDmId (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V194.Id.DiscordGuildOrDmId (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V194.Id.DiscordGuildOrDmId (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.Message.Message Evergreen.V194.Id.ThreadMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V194.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V194.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V194.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V194.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V194.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V194.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Effect.Time.Posix Evergreen.V194.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))) Evergreen.V194.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V194.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))) Evergreen.V194.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V194.LocalState.JoinGuildError
            { guildId : Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId
            , guild : Evergreen.V194.LocalState.FrontendGuild
            , owner : Evergreen.V194.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.GuildOrDmId Evergreen.V194.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.GuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.GuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.GuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))) (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V194.Id.DiscordGuildOrDmId_DmData (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V194.SessionIdHash.SessionIdHash Evergreen.V194.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V194.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V194.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V194.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.ChannelName.ChannelName (Evergreen.V194.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId)
        (Evergreen.V194.NonemptyDict.NonemptyDict
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Maybe (Evergreen.V194.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V194.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V194.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V194.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V194.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V194.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V194.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (Evergreen.V194.Discord.OptionalData String) (Evergreen.V194.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
        (Evergreen.V194.MembersAndOwner.MembersAndOwner
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V194.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V194.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V194.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V194.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels) (Maybe Evergreen.V194.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId) (Evergreen.V194.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V194.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V194.Local.Local LocalMsg Evergreen.V194.LocalState.LocalState
    , admin : Evergreen.V194.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId, Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V194.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V194.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V194.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.NonemptyDict.NonemptyDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V194.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V194.TextEditor.Model
    , profilePictureEditor : Evergreen.V194.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V194.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V194.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V194.Range.Range
                , direction : Evergreen.V194.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V194.NonemptyDict.NonemptyDict Int Evergreen.V194.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V194.NonemptyDict.NonemptyDict Int Evergreen.V194.Touch.Touch
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
    | AdminToFrontend Evergreen.V194.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V194.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V194.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V194.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V194.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V194.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V194.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V194.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V194.Ports.NotificationPermission
    , pwaStatus : Evergreen.V194.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V194.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V194.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V194.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V194.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V194.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V194.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V194.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId, Evergreen.V194.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V194.DmChannel.DmChannelId, Evergreen.V194.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId, Evergreen.V194.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId, Evergreen.V194.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V194.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V194.NonemptyDict.NonemptyDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V194.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V194.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V194.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V194.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V194.DmChannel.DmChannelId Evergreen.V194.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) Evergreen.V194.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Slack.Id Evergreen.V194.Slack.ChannelId) Evergreen.V194.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V194.OneToOne.OneToOne String (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    , slackUsers : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Slack.Id Evergreen.V194.Slack.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
    , slackServers : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Slack.Id Evergreen.V194.Slack.TeamId) (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    , slackToken : Maybe Evergreen.V194.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V194.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V194.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V194.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V194.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId, Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V194.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V194.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V194.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V194.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.LocalState.LoadingDiscordChannel (List Evergreen.V194.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V194.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId) Evergreen.V194.Sticker.StickerData
    , discordStickers : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Discord.Id Evergreen.V194.Discord.StickerId) (Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V194.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V194.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V194.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V194.Route.Route
    | SelectedFilesToAttach ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V194.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V194.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V194.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V194.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V194.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V194.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V194.NonemptyDict.NonemptyDict Int Evergreen.V194.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V194.NonemptyDict.NonemptyDict Int Evergreen.V194.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V194.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V194.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V194.Editable.Msg Evergreen.V194.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V194.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V194.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
        { fileId : Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute )
        { fileId : Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V194.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V194.Id.AnyGuildOrDmId, Evergreen.V194.Id.ThreadRoute ) (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRouteWithMessage Evergreen.V194.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V194.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V194.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) Evergreen.V194.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) Evergreen.V194.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V194.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V194.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId
        , otherUserId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V194.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRoute Evergreen.V194.MessageInput.Msg
    | MessageInputMsg Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRoute Evergreen.V194.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V194.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V194.Range.Range, Evergreen.V194.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V194.Range.Range, Evergreen.V194.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V194.Id.AnyGuildOrDmId Evergreen.V194.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V194.Id.Id Evergreen.V194.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V194.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V194.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V194.Untrusted.Untrusted Evergreen.V194.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V194.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V194.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V194.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V194.PersonName.PersonName Evergreen.V194.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V194.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V194.Slack.OAuthCode Evergreen.V194.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V194.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V194.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V194.Id.Id Evergreen.V194.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V194.EmailAddress.EmailAddress (Result Evergreen.V194.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V194.EmailAddress.EmailAddress (Result Evergreen.V194.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Evergreen.V194.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V194.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMaybeMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Result Evergreen.V194.Discord.HttpError Evergreen.V194.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V194.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Result Evergreen.V194.Discord.HttpError Evergreen.V194.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Result Evergreen.V194.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Result Evergreen.V194.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Result Evergreen.V194.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Result Evergreen.V194.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji (Result Evergreen.V194.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji (Result Evergreen.V194.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji (Result Evergreen.V194.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) Evergreen.V194.Emoji.Emoji (Result Evergreen.V194.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V194.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V194.Discord.HttpError (List ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId, Maybe Evergreen.V194.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V194.Slack.CurrentUser
            , team : Evergreen.V194.Slack.Team
            , users : List Evergreen.V194.Slack.User
            , channels : List ( Evergreen.V194.Slack.Channel, List Evergreen.V194.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Result Effect.Http.Error Evergreen.V194.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) Evergreen.V194.Discord.UserAuth (Result Evergreen.V194.Discord.HttpError Evergreen.V194.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Result Evergreen.V194.Discord.HttpError Evergreen.V194.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
        (Result
            Evergreen.V194.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId
                , members : List (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
                }
            , List
                ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId
                , { guild : Evergreen.V194.Discord.GatewayGuild
                  , channels : List Evergreen.V194.Discord.Channel
                  , icon : Maybe Evergreen.V194.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V194.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.AttachmentId, Evergreen.V194.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V194.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V194.Discord.Id Evergreen.V194.Discord.AttachmentId, Evergreen.V194.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V194.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V194.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V194.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V194.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) (Result Evergreen.V194.Discord.HttpError (List Evergreen.V194.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Result Evergreen.V194.Discord.HttpError (List Evergreen.V194.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V194.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V194.DmChannel.DmChannelId Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V194.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) Evergreen.V194.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V194.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V194.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
        (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V194.Discord.HttpError
            { guild : Evergreen.V194.Discord.GatewayGuild
            , channels : List Evergreen.V194.Discord.Channel
            , icon : Maybe Evergreen.V194.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId) (Result Evergreen.V194.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V194.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordGuildStickers (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (List ( Evergreen.V194.Id.Id Evergreen.V194.Id.StickerId, Result Effect.Http.Error Evergreen.V194.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V194.Discord.HttpError (List Evergreen.V194.Discord.StickerPack))
