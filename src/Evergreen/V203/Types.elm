module Evergreen.V203.Types exposing (..)

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
import Evergreen.V203.AiChat
import Evergreen.V203.ChannelName
import Evergreen.V203.Coord
import Evergreen.V203.CssPixels
import Evergreen.V203.Discord
import Evergreen.V203.DiscordAttachmentId
import Evergreen.V203.DiscordUserData
import Evergreen.V203.DmChannel
import Evergreen.V203.Editable
import Evergreen.V203.EmailAddress
import Evergreen.V203.Embed
import Evergreen.V203.Emoji
import Evergreen.V203.FileStatus
import Evergreen.V203.GuildName
import Evergreen.V203.Id
import Evergreen.V203.ImageEditor
import Evergreen.V203.Local
import Evergreen.V203.LocalState
import Evergreen.V203.Log
import Evergreen.V203.LoginForm
import Evergreen.V203.MembersAndOwner
import Evergreen.V203.Message
import Evergreen.V203.MessageInput
import Evergreen.V203.MessageView
import Evergreen.V203.NonemptyDict
import Evergreen.V203.NonemptySet
import Evergreen.V203.OneToOne
import Evergreen.V203.Pages.Admin
import Evergreen.V203.Pagination
import Evergreen.V203.PersonName
import Evergreen.V203.Ports
import Evergreen.V203.Postmark
import Evergreen.V203.Range
import Evergreen.V203.RichText
import Evergreen.V203.Route
import Evergreen.V203.SecretId
import Evergreen.V203.SessionIdHash
import Evergreen.V203.Slack
import Evergreen.V203.Sticker
import Evergreen.V203.TextEditor
import Evergreen.V203.ToBackendLog
import Evergreen.V203.Touch
import Evergreen.V203.TwoFactorAuthentication
import Evergreen.V203.Ui.Anim
import Evergreen.V203.Untrusted
import Evergreen.V203.User
import Evergreen.V203.UserAgent
import Evergreen.V203.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V203.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V203.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.LocalState.DiscordFrontendGuild
    , user : Evergreen.V203.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V203.SessionIdHash.SessionIdHash Evergreen.V203.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V203.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V203.Route.Route
    , windowSize : Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V203.Ports.NotificationPermission
    , pwaStatus : Evergreen.V203.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V203.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V203.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V203.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))) Evergreen.V203.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V203.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))) Evergreen.V203.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V203.GuildName.GuildName (Evergreen.V203.UserSession.ToBeFilledInByBackend (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V203.Id.GuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))) (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)))
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V203.Id.DiscordGuildOrDmId_DmData (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)))
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V203.UserSession.SetViewing
    | Local_SetName Evergreen.V203.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V203.Id.GuildOrDmId (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V203.Id.GuildOrDmId (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V203.Id.DiscordGuildOrDmId (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V203.Id.DiscordGuildOrDmId (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.Message.Message Evergreen.V203.Id.ThreadMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V203.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V203.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V203.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V203.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V203.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V203.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Effect.Time.Posix Evergreen.V203.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))) Evergreen.V203.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V203.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))) Evergreen.V203.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V203.LocalState.JoinGuildError
            { guildId : Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId
            , guild : Evergreen.V203.LocalState.FrontendGuild
            , owner : Evergreen.V203.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.GuildOrDmId Evergreen.V203.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.GuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.GuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.GuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))) (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V203.Id.DiscordGuildOrDmId_DmData (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V203.SessionIdHash.SessionIdHash Evergreen.V203.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V203.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V203.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V203.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.ChannelName.ChannelName (Evergreen.V203.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)
        (Evergreen.V203.NonemptyDict.NonemptyDict
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Maybe (Evergreen.V203.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V203.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V203.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V203.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V203.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V203.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V203.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (Evergreen.V203.Discord.OptionalData String) (Evergreen.V203.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
        (Evergreen.V203.MembersAndOwner.MembersAndOwner
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V203.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V203.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V203.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V203.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels) (Maybe Evergreen.V203.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId) (Evergreen.V203.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V203.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V203.Local.Local LocalMsg Evergreen.V203.LocalState.LocalState
    , admin : Evergreen.V203.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId, Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V203.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V203.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V203.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.NonemptyDict.NonemptyDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V203.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V203.TextEditor.Model
    , profilePictureEditor : Evergreen.V203.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V203.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V203.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V203.Range.Range
                , direction : Evergreen.V203.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V203.NonemptyDict.NonemptyDict Int Evergreen.V203.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V203.NonemptyDict.NonemptyDict Int Evergreen.V203.Touch.Touch
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
    | AdminToFrontend Evergreen.V203.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V203.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V203.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V203.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V203.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V203.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V203.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V203.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V203.Ports.NotificationPermission
    , pwaStatus : Evergreen.V203.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V203.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V203.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V203.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V203.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V203.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V203.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V203.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId, Evergreen.V203.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V203.DmChannel.DmChannelId, Evergreen.V203.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId, Evergreen.V203.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId, Evergreen.V203.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V203.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V203.NonemptyDict.NonemptyDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V203.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V203.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V203.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V203.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V203.DmChannel.DmChannelId Evergreen.V203.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) Evergreen.V203.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Slack.Id Evergreen.V203.Slack.ChannelId) Evergreen.V203.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V203.OneToOne.OneToOne String (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    , slackUsers : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Slack.Id Evergreen.V203.Slack.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    , slackServers : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Slack.Id Evergreen.V203.Slack.TeamId) (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    , slackToken : Maybe Evergreen.V203.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V203.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V203.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V203.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V203.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId, Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V203.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V203.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V203.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V203.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.LocalState.LoadingDiscordChannel (List Evergreen.V203.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V203.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId) Evergreen.V203.Sticker.StickerData
    , discordStickers : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Discord.Id Evergreen.V203.Discord.StickerId) (Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId)
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V203.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V203.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V203.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V203.Route.Route
    | SelectedFilesToAttach ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V203.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V203.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V203.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V203.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V203.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V203.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V203.NonemptyDict.NonemptyDict Int Evergreen.V203.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V203.NonemptyDict.NonemptyDict Int Evergreen.V203.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V203.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V203.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V203.Editable.Msg Evergreen.V203.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V203.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V203.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
        { fileId : Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute )
        { fileId : Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V203.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V203.Id.AnyGuildOrDmId, Evergreen.V203.Id.ThreadRoute ) (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRouteWithMessage Evergreen.V203.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V203.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V203.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) Evergreen.V203.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) Evergreen.V203.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V203.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V203.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId
        , otherUserId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V203.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRoute Evergreen.V203.MessageInput.Msg
    | MessageInputMsg Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRoute Evergreen.V203.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V203.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V203.Range.Range, Evergreen.V203.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V203.Range.Range, Evergreen.V203.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V203.Id.AnyGuildOrDmId Evergreen.V203.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V203.Id.Id Evergreen.V203.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V203.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V203.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V203.Untrusted.Untrusted Evergreen.V203.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V203.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V203.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V203.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V203.PersonName.PersonName Evergreen.V203.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V203.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V203.Slack.OAuthCode Evergreen.V203.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V203.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V203.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V203.Id.Id Evergreen.V203.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V203.EmailAddress.EmailAddress (Result Evergreen.V203.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V203.EmailAddress.EmailAddress (Result Evergreen.V203.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Evergreen.V203.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V203.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMaybeMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Result Evergreen.V203.Discord.HttpError Evergreen.V203.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V203.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Result Evergreen.V203.Discord.HttpError Evergreen.V203.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Result Evergreen.V203.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Result Evergreen.V203.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Result Evergreen.V203.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Result Evergreen.V203.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji (Result Evergreen.V203.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji (Result Evergreen.V203.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji (Result Evergreen.V203.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) Evergreen.V203.Emoji.Emoji (Result Evergreen.V203.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V203.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V203.Discord.HttpError (List ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId, Maybe Evergreen.V203.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V203.Slack.CurrentUser
            , team : Evergreen.V203.Slack.Team
            , users : List Evergreen.V203.Slack.User
            , channels : List ( Evergreen.V203.Slack.Channel, List Evergreen.V203.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Result Effect.Http.Error Evergreen.V203.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Discord.UserAuth (Result Evergreen.V203.Discord.HttpError Evergreen.V203.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Result Evergreen.V203.Discord.HttpError Evergreen.V203.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
        (Result
            Evergreen.V203.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId
                , members : List (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
                }
            , List
                ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId
                , { guild : Evergreen.V203.Discord.GatewayGuild
                  , channels : List Evergreen.V203.Discord.Channel
                  , icon : Maybe Evergreen.V203.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V203.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.AttachmentId, Evergreen.V203.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V203.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V203.Discord.Id Evergreen.V203.Discord.AttachmentId, Evergreen.V203.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V203.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V203.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V203.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V203.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) (Result Evergreen.V203.Discord.HttpError (List Evergreen.V203.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Result Evergreen.V203.Discord.HttpError (List Evergreen.V203.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V203.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V203.DmChannel.DmChannelId Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V203.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) Evergreen.V203.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V203.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V203.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
        (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V203.Discord.HttpError
            { guild : Evergreen.V203.Discord.GatewayGuild
            , channels : List Evergreen.V203.Discord.Channel
            , icon : Maybe Evergreen.V203.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId) (Result Evergreen.V203.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V203.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (List ( Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId, Result Effect.Http.Error Evergreen.V203.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V203.Id.Id Evergreen.V203.Id.StickerId, Result Effect.Http.Error Evergreen.V203.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V203.Discord.HttpError (List Evergreen.V203.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
