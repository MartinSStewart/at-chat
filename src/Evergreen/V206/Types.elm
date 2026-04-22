module Evergreen.V206.Types exposing (..)

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
import Evergreen.V206.AiChat
import Evergreen.V206.ChannelName
import Evergreen.V206.Coord
import Evergreen.V206.CssPixels
import Evergreen.V206.Discord
import Evergreen.V206.DiscordAttachmentId
import Evergreen.V206.DiscordUserData
import Evergreen.V206.DmChannel
import Evergreen.V206.Editable
import Evergreen.V206.EmailAddress
import Evergreen.V206.Embed
import Evergreen.V206.Emoji
import Evergreen.V206.FileStatus
import Evergreen.V206.GuildName
import Evergreen.V206.Id
import Evergreen.V206.ImageEditor
import Evergreen.V206.Local
import Evergreen.V206.LocalState
import Evergreen.V206.Log
import Evergreen.V206.LoginForm
import Evergreen.V206.MembersAndOwner
import Evergreen.V206.Message
import Evergreen.V206.MessageInput
import Evergreen.V206.MessageView
import Evergreen.V206.NonemptyDict
import Evergreen.V206.NonemptySet
import Evergreen.V206.OneToOne
import Evergreen.V206.Pages.Admin
import Evergreen.V206.Pagination
import Evergreen.V206.PersonName
import Evergreen.V206.Ports
import Evergreen.V206.Postmark
import Evergreen.V206.Range
import Evergreen.V206.RichText
import Evergreen.V206.Route
import Evergreen.V206.SecretId
import Evergreen.V206.SessionIdHash
import Evergreen.V206.Slack
import Evergreen.V206.Sticker
import Evergreen.V206.TextEditor
import Evergreen.V206.ToBackendLog
import Evergreen.V206.Touch
import Evergreen.V206.TwoFactorAuthentication
import Evergreen.V206.Ui.Anim
import Evergreen.V206.Untrusted
import Evergreen.V206.User
import Evergreen.V206.UserAgent
import Evergreen.V206.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V206.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V206.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.LocalState.DiscordFrontendGuild
    , user : Evergreen.V206.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V206.SessionIdHash.SessionIdHash Evergreen.V206.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V206.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V206.Route.Route
    , windowSize : Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V206.Ports.NotificationPermission
    , pwaStatus : Evergreen.V206.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V206.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V206.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V206.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))) Evergreen.V206.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V206.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))) Evergreen.V206.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V206.GuildName.GuildName (Evergreen.V206.UserSession.ToBeFilledInByBackend (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V206.Id.GuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))) (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V206.Id.DiscordGuildOrDmId_DmData (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V206.UserSession.SetViewing
    | Local_SetName Evergreen.V206.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V206.Id.GuildOrDmId (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V206.Id.GuildOrDmId (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V206.Id.DiscordGuildOrDmId (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V206.Id.DiscordGuildOrDmId (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.Message.Message Evergreen.V206.Id.ThreadMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V206.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V206.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V206.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V206.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V206.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V206.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Effect.Time.Posix Evergreen.V206.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))) Evergreen.V206.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V206.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))) Evergreen.V206.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V206.LocalState.JoinGuildError
            { guildId : Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId
            , guild : Evergreen.V206.LocalState.FrontendGuild
            , owner : Evergreen.V206.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.GuildOrDmId Evergreen.V206.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.GuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.GuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.GuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))) (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V206.Id.DiscordGuildOrDmId_DmData (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V206.SessionIdHash.SessionIdHash Evergreen.V206.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V206.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V206.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V206.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.ChannelName.ChannelName (Evergreen.V206.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)
        (Evergreen.V206.NonemptyDict.NonemptyDict
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Maybe (Evergreen.V206.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V206.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V206.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V206.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V206.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V206.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V206.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (Evergreen.V206.Discord.OptionalData String) (Evergreen.V206.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
        (Evergreen.V206.MembersAndOwner.MembersAndOwner
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V206.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V206.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V206.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V206.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels) (Maybe Evergreen.V206.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ThreadMessageId) (Evergreen.V206.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V206.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V206.Local.Local LocalMsg Evergreen.V206.LocalState.LocalState
    , admin : Evergreen.V206.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId, Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V206.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V206.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V206.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.NonemptyDict.NonemptyDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V206.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V206.TextEditor.Model
    , profilePictureEditor : Evergreen.V206.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V206.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V206.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V206.Range.Range
                , direction : Evergreen.V206.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V206.NonemptyDict.NonemptyDict Int Evergreen.V206.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V206.NonemptyDict.NonemptyDict Int Evergreen.V206.Touch.Touch
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
    | AdminToFrontend Evergreen.V206.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V206.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V206.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V206.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V206.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V206.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V206.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V206.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V206.Ports.NotificationPermission
    , pwaStatus : Evergreen.V206.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V206.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V206.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V206.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V206.Id.Id Evergreen.V206.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V206.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V206.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V206.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V206.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId, Evergreen.V206.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V206.DmChannel.DmChannelId, Evergreen.V206.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId, Evergreen.V206.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId, Evergreen.V206.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V206.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V206.NonemptyDict.NonemptyDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V206.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V206.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V206.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V206.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V206.DmChannel.DmChannelId Evergreen.V206.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) Evergreen.V206.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Slack.Id Evergreen.V206.Slack.ChannelId) Evergreen.V206.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V206.OneToOne.OneToOne String (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    , slackUsers : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Slack.Id Evergreen.V206.Slack.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
    , slackServers : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Slack.Id Evergreen.V206.Slack.TeamId) (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    , slackToken : Maybe Evergreen.V206.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V206.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V206.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V206.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V206.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId, Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V206.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V206.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V206.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V206.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.LocalState.LoadingDiscordChannel (List Evergreen.V206.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V206.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId) Evergreen.V206.Sticker.StickerData
    , discordStickers : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Discord.Id Evergreen.V206.Discord.StickerId) (Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId)
    , postmarkApiKey : Evergreen.V206.Postmark.ApiKey
    , serverSecret : Evergreen.V206.SecretId.SecretId Evergreen.V206.SecretId.ServerSecret
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V206.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V206.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V206.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V206.Route.Route
    | SelectedFilesToAttach ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V206.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V206.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V206.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V206.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V206.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V206.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V206.NonemptyDict.NonemptyDict Int Evergreen.V206.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V206.NonemptyDict.NonemptyDict Int Evergreen.V206.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V206.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V206.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V206.Editable.Msg Evergreen.V206.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V206.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V206.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
        { fileId : Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute )
        { fileId : Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V206.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V206.Id.AnyGuildOrDmId, Evergreen.V206.Id.ThreadRoute ) (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRouteWithMessage Evergreen.V206.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V206.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V206.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) Evergreen.V206.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) Evergreen.V206.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V206.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V206.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId
        , otherUserId : Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V206.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRoute Evergreen.V206.MessageInput.Msg
    | MessageInputMsg Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRoute Evergreen.V206.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V206.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V206.Range.Range, Evergreen.V206.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V206.Range.Range, Evergreen.V206.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V206.Id.AnyGuildOrDmId Evergreen.V206.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V206.Id.Id Evergreen.V206.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V206.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V206.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V206.Untrusted.Untrusted Evergreen.V206.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V206.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V206.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V206.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.SecretId.SecretId Evergreen.V206.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V206.PersonName.PersonName Evergreen.V206.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V206.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V206.Slack.OAuthCode Evergreen.V206.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V206.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V206.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V206.Id.Id Evergreen.V206.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V206.EmailAddress.EmailAddress (Result Evergreen.V206.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V206.EmailAddress.EmailAddress (Result Evergreen.V206.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Evergreen.V206.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V206.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMaybeMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Result Evergreen.V206.Discord.HttpError Evergreen.V206.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V206.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Result Evergreen.V206.Discord.HttpError Evergreen.V206.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Result Evergreen.V206.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Result Evergreen.V206.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Result Evergreen.V206.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Result Evergreen.V206.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji (Result Evergreen.V206.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji (Result Evergreen.V206.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji (Result Evergreen.V206.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) Evergreen.V206.Emoji.Emoji (Result Evergreen.V206.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V206.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V206.Discord.HttpError (List ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId, Maybe Evergreen.V206.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V206.Slack.CurrentUser
            , team : Evergreen.V206.Slack.Team
            , users : List Evergreen.V206.Slack.User
            , channels : List ( Evergreen.V206.Slack.Channel, List Evergreen.V206.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Result Effect.Http.Error Evergreen.V206.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) Evergreen.V206.Discord.UserAuth (Result Evergreen.V206.Discord.HttpError Evergreen.V206.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Result Evergreen.V206.Discord.HttpError Evergreen.V206.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
        (Result
            Evergreen.V206.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId
                , members : List (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
                }
            , List
                ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId
                , { guild : Evergreen.V206.Discord.GatewayGuild
                  , channels : List Evergreen.V206.Discord.Channel
                  , icon : Maybe Evergreen.V206.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V206.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.AttachmentId, Evergreen.V206.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V206.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V206.Discord.Id Evergreen.V206.Discord.AttachmentId, Evergreen.V206.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V206.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V206.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V206.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V206.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) (Result Evergreen.V206.Discord.HttpError (List Evergreen.V206.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Result Evergreen.V206.Discord.HttpError (List Evergreen.V206.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V206.Id.Id Evergreen.V206.Id.GuildId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V206.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V206.DmChannel.DmChannelId Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V206.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Evergreen.V206.Discord.Id Evergreen.V206.Discord.ChannelId) Evergreen.V206.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V206.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V206.Discord.Id Evergreen.V206.Discord.PrivateChannelId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V206.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
        (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V206.Discord.HttpError
            { guild : Evergreen.V206.Discord.GatewayGuild
            , channels : List Evergreen.V206.Discord.Channel
            , icon : Maybe Evergreen.V206.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V206.Discord.Id Evergreen.V206.Discord.GuildId) (Result Evergreen.V206.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V206.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (List ( Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId, Result Effect.Http.Error Evergreen.V206.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V206.Id.Id Evergreen.V206.Id.StickerId, Result Effect.Http.Error Evergreen.V206.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V206.Discord.HttpError (List Evergreen.V206.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
