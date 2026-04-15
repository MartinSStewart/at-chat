module Evergreen.V201.Types exposing (..)

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
import Evergreen.V201.AiChat
import Evergreen.V201.ChannelName
import Evergreen.V201.Coord
import Evergreen.V201.CssPixels
import Evergreen.V201.Discord
import Evergreen.V201.DiscordAttachmentId
import Evergreen.V201.DiscordUserData
import Evergreen.V201.DmChannel
import Evergreen.V201.Editable
import Evergreen.V201.EmailAddress
import Evergreen.V201.Embed
import Evergreen.V201.Emoji
import Evergreen.V201.FileStatus
import Evergreen.V201.GuildName
import Evergreen.V201.Id
import Evergreen.V201.ImageEditor
import Evergreen.V201.Local
import Evergreen.V201.LocalState
import Evergreen.V201.Log
import Evergreen.V201.LoginForm
import Evergreen.V201.MembersAndOwner
import Evergreen.V201.Message
import Evergreen.V201.MessageInput
import Evergreen.V201.MessageView
import Evergreen.V201.NonemptyDict
import Evergreen.V201.NonemptySet
import Evergreen.V201.OneToOne
import Evergreen.V201.Pages.Admin
import Evergreen.V201.Pagination
import Evergreen.V201.PersonName
import Evergreen.V201.Ports
import Evergreen.V201.Postmark
import Evergreen.V201.Range
import Evergreen.V201.RichText
import Evergreen.V201.Route
import Evergreen.V201.SecretId
import Evergreen.V201.SessionIdHash
import Evergreen.V201.Slack
import Evergreen.V201.Sticker
import Evergreen.V201.TextEditor
import Evergreen.V201.ToBackendLog
import Evergreen.V201.Touch
import Evergreen.V201.TwoFactorAuthentication
import Evergreen.V201.Ui.Anim
import Evergreen.V201.Untrusted
import Evergreen.V201.User
import Evergreen.V201.UserAgent
import Evergreen.V201.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V201.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V201.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.LocalState.DiscordFrontendGuild
    , user : Evergreen.V201.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V201.SessionIdHash.SessionIdHash Evergreen.V201.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V201.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V201.Route.Route
    , windowSize : Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V201.Ports.NotificationPermission
    , pwaStatus : Evergreen.V201.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V201.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V201.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V201.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))) Evergreen.V201.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V201.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))) Evergreen.V201.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V201.GuildName.GuildName (Evergreen.V201.UserSession.ToBeFilledInByBackend (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V201.Id.GuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))) (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V201.Id.DiscordGuildOrDmId_DmData (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V201.UserSession.SetViewing
    | Local_SetName Evergreen.V201.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V201.Id.GuildOrDmId (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V201.Id.GuildOrDmId (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V201.Id.DiscordGuildOrDmId (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V201.Id.DiscordGuildOrDmId (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.Message.Message Evergreen.V201.Id.ThreadMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V201.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V201.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V201.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V201.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V201.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V201.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Effect.Time.Posix Evergreen.V201.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))) Evergreen.V201.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V201.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))) Evergreen.V201.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V201.LocalState.JoinGuildError
            { guildId : Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId
            , guild : Evergreen.V201.LocalState.FrontendGuild
            , owner : Evergreen.V201.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.GuildOrDmId Evergreen.V201.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.GuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.GuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.GuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))) (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V201.Id.DiscordGuildOrDmId_DmData (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V201.SessionIdHash.SessionIdHash Evergreen.V201.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V201.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V201.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V201.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.ChannelName.ChannelName (Evergreen.V201.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)
        (Evergreen.V201.NonemptyDict.NonemptyDict
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Maybe (Evergreen.V201.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V201.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V201.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V201.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V201.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V201.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V201.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (Evergreen.V201.Discord.OptionalData String) (Evergreen.V201.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
        (Evergreen.V201.MembersAndOwner.MembersAndOwner
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V201.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V201.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V201.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V201.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels) (Maybe Evergreen.V201.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId) (Evergreen.V201.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V201.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V201.Local.Local LocalMsg Evergreen.V201.LocalState.LocalState
    , admin : Evergreen.V201.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId, Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V201.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V201.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V201.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.NonemptyDict.NonemptyDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V201.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V201.TextEditor.Model
    , profilePictureEditor : Evergreen.V201.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V201.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V201.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V201.Range.Range
                , direction : Evergreen.V201.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V201.NonemptyDict.NonemptyDict Int Evergreen.V201.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V201.NonemptyDict.NonemptyDict Int Evergreen.V201.Touch.Touch
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
    | AdminToFrontend Evergreen.V201.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V201.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V201.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V201.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V201.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V201.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V201.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V201.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V201.Ports.NotificationPermission
    , pwaStatus : Evergreen.V201.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V201.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V201.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V201.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V201.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V201.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V201.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V201.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId, Evergreen.V201.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V201.DmChannel.DmChannelId, Evergreen.V201.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId, Evergreen.V201.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId, Evergreen.V201.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V201.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V201.NonemptyDict.NonemptyDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V201.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V201.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V201.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V201.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V201.DmChannel.DmChannelId Evergreen.V201.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) Evergreen.V201.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Slack.Id Evergreen.V201.Slack.ChannelId) Evergreen.V201.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V201.OneToOne.OneToOne String (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    , slackUsers : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Slack.Id Evergreen.V201.Slack.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    , slackServers : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Slack.Id Evergreen.V201.Slack.TeamId) (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    , slackToken : Maybe Evergreen.V201.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V201.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V201.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V201.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V201.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId, Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V201.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V201.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V201.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V201.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.LocalState.LoadingDiscordChannel (List Evergreen.V201.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V201.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId) Evergreen.V201.Sticker.StickerData
    , discordStickers : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Discord.Id Evergreen.V201.Discord.StickerId) (Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V201.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V201.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V201.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V201.Route.Route
    | SelectedFilesToAttach ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V201.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V201.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V201.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V201.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V201.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V201.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V201.NonemptyDict.NonemptyDict Int Evergreen.V201.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V201.NonemptyDict.NonemptyDict Int Evergreen.V201.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V201.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V201.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V201.Editable.Msg Evergreen.V201.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V201.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V201.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
        { fileId : Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute )
        { fileId : Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V201.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V201.Id.AnyGuildOrDmId, Evergreen.V201.Id.ThreadRoute ) (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRouteWithMessage Evergreen.V201.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V201.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V201.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) Evergreen.V201.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) Evergreen.V201.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V201.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V201.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId
        , otherUserId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V201.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRoute Evergreen.V201.MessageInput.Msg
    | MessageInputMsg Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRoute Evergreen.V201.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V201.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V201.Range.Range, Evergreen.V201.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V201.Range.Range, Evergreen.V201.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V201.Id.AnyGuildOrDmId Evergreen.V201.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V201.Id.Id Evergreen.V201.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V201.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V201.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V201.Untrusted.Untrusted Evergreen.V201.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V201.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V201.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V201.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V201.PersonName.PersonName Evergreen.V201.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V201.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V201.Slack.OAuthCode Evergreen.V201.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V201.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V201.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V201.Id.Id Evergreen.V201.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V201.EmailAddress.EmailAddress (Result Evergreen.V201.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V201.EmailAddress.EmailAddress (Result Evergreen.V201.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Evergreen.V201.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V201.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMaybeMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Result Evergreen.V201.Discord.HttpError Evergreen.V201.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V201.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Result Evergreen.V201.Discord.HttpError Evergreen.V201.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Result Evergreen.V201.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Result Evergreen.V201.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Result Evergreen.V201.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Result Evergreen.V201.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji (Result Evergreen.V201.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji (Result Evergreen.V201.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji (Result Evergreen.V201.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) Evergreen.V201.Emoji.Emoji (Result Evergreen.V201.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V201.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V201.Discord.HttpError (List ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId, Maybe Evergreen.V201.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V201.Slack.CurrentUser
            , team : Evergreen.V201.Slack.Team
            , users : List Evergreen.V201.Slack.User
            , channels : List ( Evergreen.V201.Slack.Channel, List Evergreen.V201.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Result Effect.Http.Error Evergreen.V201.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Discord.UserAuth (Result Evergreen.V201.Discord.HttpError Evergreen.V201.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Result Evergreen.V201.Discord.HttpError Evergreen.V201.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
        (Result
            Evergreen.V201.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId
                , members : List (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
                }
            , List
                ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId
                , { guild : Evergreen.V201.Discord.GatewayGuild
                  , channels : List Evergreen.V201.Discord.Channel
                  , icon : Maybe Evergreen.V201.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V201.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.AttachmentId, Evergreen.V201.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V201.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V201.Discord.Id Evergreen.V201.Discord.AttachmentId, Evergreen.V201.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V201.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V201.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V201.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V201.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) (Result Evergreen.V201.Discord.HttpError (List Evergreen.V201.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Result Evergreen.V201.Discord.HttpError (List Evergreen.V201.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V201.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V201.DmChannel.DmChannelId Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V201.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) Evergreen.V201.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V201.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V201.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
        (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V201.Discord.HttpError
            { guild : Evergreen.V201.Discord.GatewayGuild
            , channels : List Evergreen.V201.Discord.Channel
            , icon : Maybe Evergreen.V201.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId) (Result Evergreen.V201.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V201.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (List ( Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId, Result Effect.Http.Error Evergreen.V201.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V201.Id.Id Evergreen.V201.Id.StickerId, Result Effect.Http.Error Evergreen.V201.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V201.Discord.HttpError (List Evergreen.V201.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
