module Evergreen.V193.Types exposing (..)

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
import Evergreen.V193.AiChat
import Evergreen.V193.ChannelName
import Evergreen.V193.Coord
import Evergreen.V193.CssPixels
import Evergreen.V193.Discord
import Evergreen.V193.DiscordAttachmentId
import Evergreen.V193.DiscordUserData
import Evergreen.V193.DmChannel
import Evergreen.V193.Editable
import Evergreen.V193.EmailAddress
import Evergreen.V193.Embed
import Evergreen.V193.Emoji
import Evergreen.V193.FileStatus
import Evergreen.V193.GuildName
import Evergreen.V193.Id
import Evergreen.V193.ImageEditor
import Evergreen.V193.Local
import Evergreen.V193.LocalState
import Evergreen.V193.Log
import Evergreen.V193.LoginForm
import Evergreen.V193.MembersAndOwner
import Evergreen.V193.Message
import Evergreen.V193.MessageInput
import Evergreen.V193.MessageView
import Evergreen.V193.NonemptyDict
import Evergreen.V193.NonemptySet
import Evergreen.V193.OneToOne
import Evergreen.V193.Pages.Admin
import Evergreen.V193.Pagination
import Evergreen.V193.PersonName
import Evergreen.V193.Ports
import Evergreen.V193.Postmark
import Evergreen.V193.Range
import Evergreen.V193.RichText
import Evergreen.V193.Route
import Evergreen.V193.SecretId
import Evergreen.V193.SessionIdHash
import Evergreen.V193.Slack
import Evergreen.V193.Sticker
import Evergreen.V193.TextEditor
import Evergreen.V193.ToBackendLog
import Evergreen.V193.Touch
import Evergreen.V193.TwoFactorAuthentication
import Evergreen.V193.Ui.Anim
import Evergreen.V193.Untrusted
import Evergreen.V193.User
import Evergreen.V193.UserAgent
import Evergreen.V193.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V193.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V193.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.LocalState.DiscordFrontendGuild
    , user : Evergreen.V193.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V193.SessionIdHash.SessionIdHash Evergreen.V193.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V193.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V193.Route.Route
    , windowSize : Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V193.Ports.NotificationPermission
    , pwaStatus : Evergreen.V193.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V193.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V193.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V193.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))) Evergreen.V193.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V193.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))) Evergreen.V193.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V193.GuildName.GuildName (Evergreen.V193.UserSession.ToBeFilledInByBackend (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V193.Id.GuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))) (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V193.Id.DiscordGuildOrDmId_DmData (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V193.UserSession.SetViewing
    | Local_SetName Evergreen.V193.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V193.Id.GuildOrDmId (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V193.Id.GuildOrDmId (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V193.Id.DiscordGuildOrDmId (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V193.Id.DiscordGuildOrDmId (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.Message.Message Evergreen.V193.Id.ThreadMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V193.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V193.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V193.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V193.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V193.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V193.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Effect.Time.Posix Evergreen.V193.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))) Evergreen.V193.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V193.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))) Evergreen.V193.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V193.LocalState.JoinGuildError
            { guildId : Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId
            , guild : Evergreen.V193.LocalState.FrontendGuild
            , owner : Evergreen.V193.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.GuildOrDmId Evergreen.V193.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.GuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.GuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.GuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))) (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V193.Id.DiscordGuildOrDmId_DmData (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V193.SessionIdHash.SessionIdHash Evergreen.V193.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V193.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V193.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V193.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.ChannelName.ChannelName (Evergreen.V193.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId)
        (Evergreen.V193.NonemptyDict.NonemptyDict
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Maybe (Evergreen.V193.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V193.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V193.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V193.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V193.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V193.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V193.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (Evergreen.V193.Discord.OptionalData String) (Evergreen.V193.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
        (Evergreen.V193.MembersAndOwner.MembersAndOwner
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V193.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V193.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V193.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V193.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels) (Maybe Evergreen.V193.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId) (Evergreen.V193.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V193.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V193.Local.Local LocalMsg Evergreen.V193.LocalState.LocalState
    , admin : Evergreen.V193.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId, Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V193.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V193.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V193.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.NonemptyDict.NonemptyDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V193.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V193.TextEditor.Model
    , profilePictureEditor : Evergreen.V193.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V193.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V193.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V193.Range.Range
                , direction : Evergreen.V193.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V193.NonemptyDict.NonemptyDict Int Evergreen.V193.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V193.NonemptyDict.NonemptyDict Int Evergreen.V193.Touch.Touch
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
    | AdminToFrontend Evergreen.V193.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V193.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V193.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V193.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V193.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V193.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V193.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V193.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V193.Ports.NotificationPermission
    , pwaStatus : Evergreen.V193.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V193.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V193.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V193.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V193.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V193.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V193.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V193.FileStatus.ImageMetadata
    }


type alias ExportState =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId, Evergreen.V193.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V193.DmChannel.DmChannelId, Evergreen.V193.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId, Evergreen.V193.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId, Evergreen.V193.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    , exportSubset : Evergreen.V193.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V193.NonemptyDict.NonemptyDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V193.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V193.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V193.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V193.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V193.DmChannel.DmChannelId Evergreen.V193.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) Evergreen.V193.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Slack.Id Evergreen.V193.Slack.ChannelId) Evergreen.V193.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V193.OneToOne.OneToOne String (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    , slackUsers : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Slack.Id Evergreen.V193.Slack.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
    , slackServers : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Slack.Id Evergreen.V193.Slack.TeamId) (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    , slackToken : Maybe Evergreen.V193.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V193.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V193.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V193.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V193.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId, Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V193.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V193.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V193.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V193.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.LocalState.LoadingDiscordChannel (List Evergreen.V193.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V193.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId) Evergreen.V193.Sticker.StickerData
    , discordStickers : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Discord.Id Evergreen.V193.Discord.StickerId) (Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V193.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V193.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V193.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V193.Route.Route
    | SelectedFilesToAttach ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V193.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V193.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V193.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V193.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V193.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V193.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V193.NonemptyDict.NonemptyDict Int Evergreen.V193.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V193.NonemptyDict.NonemptyDict Int Evergreen.V193.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V193.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V193.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V193.Editable.Msg Evergreen.V193.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V193.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V193.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId)
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId)
    | EditMessage_SelectedFilesToAttach ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V193.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V193.Id.AnyGuildOrDmId, Evergreen.V193.Id.ThreadRoute ) (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRouteWithMessage Evergreen.V193.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V193.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V193.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) Evergreen.V193.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) Evergreen.V193.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V193.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V193.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId
        , otherUserId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V193.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRoute Evergreen.V193.MessageInput.Msg
    | MessageInputMsg Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRoute Evergreen.V193.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V193.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V193.Range.Range, Evergreen.V193.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V193.Range.Range, Evergreen.V193.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V193.Id.AnyGuildOrDmId Evergreen.V193.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V193.Id.Id Evergreen.V193.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V193.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V193.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V193.Untrusted.Untrusted Evergreen.V193.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V193.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V193.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V193.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V193.PersonName.PersonName Evergreen.V193.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V193.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V193.Slack.OAuthCode Evergreen.V193.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V193.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V193.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V193.Id.Id Evergreen.V193.Pagination.PageId))


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V193.EmailAddress.EmailAddress (Result Evergreen.V193.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V193.EmailAddress.EmailAddress (Result Evergreen.V193.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Evergreen.V193.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V193.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMaybeMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Result Evergreen.V193.Discord.HttpError Evergreen.V193.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V193.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Result Evergreen.V193.Discord.HttpError Evergreen.V193.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Result Evergreen.V193.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Result Evergreen.V193.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Result Evergreen.V193.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Result Evergreen.V193.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji (Result Evergreen.V193.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji (Result Evergreen.V193.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji (Result Evergreen.V193.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) Evergreen.V193.Emoji.Emoji (Result Evergreen.V193.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V193.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V193.Discord.HttpError (List ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId, Maybe Evergreen.V193.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V193.Slack.CurrentUser
            , team : Evergreen.V193.Slack.Team
            , users : List Evergreen.V193.Slack.User
            , channels : List ( Evergreen.V193.Slack.Channel, List Evergreen.V193.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Result Effect.Http.Error Evergreen.V193.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) Evergreen.V193.Discord.UserAuth (Result Evergreen.V193.Discord.HttpError Evergreen.V193.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Result Evergreen.V193.Discord.HttpError Evergreen.V193.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
        (Result
            Evergreen.V193.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId
                , members : List (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
                }
            , List
                ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId
                , { guild : Evergreen.V193.Discord.GatewayGuild
                  , channels : List Evergreen.V193.Discord.Channel
                  , icon : Maybe Evergreen.V193.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V193.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.AttachmentId, Evergreen.V193.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V193.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V193.Discord.Id Evergreen.V193.Discord.AttachmentId, Evergreen.V193.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V193.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V193.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V193.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V193.FileStatus.UploadResponse )))
    | ExportBackendStep
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) (Result Evergreen.V193.Discord.HttpError (List Evergreen.V193.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Result Evergreen.V193.Discord.HttpError (List Evergreen.V193.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V193.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V193.DmChannel.DmChannelId Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V193.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) Evergreen.V193.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V193.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V193.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
        (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V193.Discord.HttpError
            { guild : Evergreen.V193.Discord.GatewayGuild
            , channels : List Evergreen.V193.Discord.Channel
            , icon : Maybe Evergreen.V193.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId) (Result Evergreen.V193.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V193.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordGuildStickers (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (List ( Evergreen.V193.Id.Id Evergreen.V193.Id.StickerId, Result Effect.Http.Error Evergreen.V193.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V193.Discord.HttpError (List Evergreen.V193.Discord.StickerPack))
