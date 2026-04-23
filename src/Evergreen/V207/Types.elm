module Evergreen.V207.Types exposing (..)

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
import Evergreen.V207.AiChat
import Evergreen.V207.ChannelName
import Evergreen.V207.Coord
import Evergreen.V207.CssPixels
import Evergreen.V207.Discord
import Evergreen.V207.DiscordAttachmentId
import Evergreen.V207.DiscordUserData
import Evergreen.V207.DmChannel
import Evergreen.V207.Editable
import Evergreen.V207.EmailAddress
import Evergreen.V207.Embed
import Evergreen.V207.Emoji
import Evergreen.V207.FileStatus
import Evergreen.V207.GuildName
import Evergreen.V207.Id
import Evergreen.V207.ImageEditor
import Evergreen.V207.Local
import Evergreen.V207.LocalState
import Evergreen.V207.Log
import Evergreen.V207.LoginForm
import Evergreen.V207.MembersAndOwner
import Evergreen.V207.Message
import Evergreen.V207.MessageInput
import Evergreen.V207.MessageView
import Evergreen.V207.NonemptyDict
import Evergreen.V207.NonemptySet
import Evergreen.V207.OneToOne
import Evergreen.V207.Pages.Admin
import Evergreen.V207.Pagination
import Evergreen.V207.PersonName
import Evergreen.V207.Ports
import Evergreen.V207.Postmark
import Evergreen.V207.Range
import Evergreen.V207.RichText
import Evergreen.V207.Route
import Evergreen.V207.SecretId
import Evergreen.V207.SessionIdHash
import Evergreen.V207.Slack
import Evergreen.V207.Sticker
import Evergreen.V207.TextEditor
import Evergreen.V207.ToBackendLog
import Evergreen.V207.Touch
import Evergreen.V207.TwoFactorAuthentication
import Evergreen.V207.Ui.Anim
import Evergreen.V207.Untrusted
import Evergreen.V207.User
import Evergreen.V207.UserAgent
import Evergreen.V207.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V207.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V207.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.LocalState.DiscordFrontendGuild
    , user : Evergreen.V207.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V207.SessionIdHash.SessionIdHash Evergreen.V207.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V207.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V207.Route.Route
    , windowSize : Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V207.Ports.NotificationPermission
    , pwaStatus : Evergreen.V207.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V207.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V207.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V207.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V207.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V207.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V207.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V207.GuildName.GuildName (Evergreen.V207.UserSession.ToBeFilledInByBackend (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V207.Id.GuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V207.Id.DiscordGuildOrDmId_DmData (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V207.UserSession.SetViewing
    | Local_SetName Evergreen.V207.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V207.Id.GuildOrDmId (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V207.Id.GuildOrDmId (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V207.Id.DiscordGuildOrDmId (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V207.Id.DiscordGuildOrDmId (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.Message.Message Evergreen.V207.Id.ThreadMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V207.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V207.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V207.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V207.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V207.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V207.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Effect.Time.Posix Evergreen.V207.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))) Evergreen.V207.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V207.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))) Evergreen.V207.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V207.LocalState.JoinGuildError
            { guildId : Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId
            , guild : Evergreen.V207.LocalState.FrontendGuild
            , owner : Evergreen.V207.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.GuildOrDmId Evergreen.V207.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.GuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.GuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.GuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))) (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V207.Id.DiscordGuildOrDmId_DmData (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V207.SessionIdHash.SessionIdHash Evergreen.V207.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V207.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V207.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V207.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.ChannelName.ChannelName (Evergreen.V207.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)
        (Evergreen.V207.NonemptyDict.NonemptyDict
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Maybe (Evergreen.V207.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V207.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V207.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V207.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V207.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V207.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V207.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (Evergreen.V207.Discord.OptionalData String) (Evergreen.V207.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
        (Evergreen.V207.MembersAndOwner.MembersAndOwner
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V207.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V207.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V207.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V207.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels) (Maybe Evergreen.V207.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId) (Evergreen.V207.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V207.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V207.Local.Local LocalMsg Evergreen.V207.LocalState.LocalState
    , admin : Evergreen.V207.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId, Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V207.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V207.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V207.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.NonemptyDict.NonemptyDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V207.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V207.TextEditor.Model
    , profilePictureEditor : Evergreen.V207.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V207.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V207.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V207.Range.Range
                , direction : Evergreen.V207.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V207.NonemptyDict.NonemptyDict Int Evergreen.V207.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V207.NonemptyDict.NonemptyDict Int Evergreen.V207.Touch.Touch
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
    | AdminToFrontend Evergreen.V207.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V207.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V207.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V207.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V207.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V207.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V207.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V207.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V207.Ports.NotificationPermission
    , pwaStatus : Evergreen.V207.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V207.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V207.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V207.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V207.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V207.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V207.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V207.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId, Evergreen.V207.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V207.DmChannel.DmChannelId, Evergreen.V207.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId, Evergreen.V207.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId, Evergreen.V207.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V207.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V207.NonemptyDict.NonemptyDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V207.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V207.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V207.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V207.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V207.DmChannel.DmChannelId Evergreen.V207.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) Evergreen.V207.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Slack.Id Evergreen.V207.Slack.ChannelId) Evergreen.V207.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V207.OneToOne.OneToOne String (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    , slackUsers : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Slack.Id Evergreen.V207.Slack.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
    , slackServers : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Slack.Id Evergreen.V207.Slack.TeamId) (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    , slackToken : Maybe Evergreen.V207.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V207.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V207.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V207.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V207.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId, Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V207.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V207.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V207.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V207.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.LocalState.LoadingDiscordChannel (List Evergreen.V207.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V207.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId) Evergreen.V207.Sticker.StickerData
    , discordStickers : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Discord.Id Evergreen.V207.Discord.StickerId) (Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId)
    , postmarkApiKey : Evergreen.V207.Postmark.ApiKey
    , serverSecret : Evergreen.V207.SecretId.SecretId Evergreen.V207.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V207.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V207.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V207.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V207.Route.Route
    | SelectedFilesToAttach ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V207.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V207.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V207.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V207.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V207.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V207.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V207.NonemptyDict.NonemptyDict Int Evergreen.V207.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V207.NonemptyDict.NonemptyDict Int Evergreen.V207.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V207.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V207.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V207.Editable.Msg Evergreen.V207.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V207.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V207.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
        { fileId : Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute )
        { fileId : Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V207.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V207.Id.AnyGuildOrDmId, Evergreen.V207.Id.ThreadRoute ) (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRouteWithMessage Evergreen.V207.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V207.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V207.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) Evergreen.V207.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) Evergreen.V207.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V207.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V207.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId
        , otherUserId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V207.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRoute Evergreen.V207.MessageInput.Msg
    | MessageInputMsg Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRoute Evergreen.V207.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V207.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V207.Range.Range, Evergreen.V207.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V207.Range.Range, Evergreen.V207.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V207.Id.AnyGuildOrDmId Evergreen.V207.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V207.Id.Id Evergreen.V207.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V207.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V207.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V207.Untrusted.Untrusted Evergreen.V207.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V207.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V207.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V207.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V207.PersonName.PersonName Evergreen.V207.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V207.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V207.Slack.OAuthCode Evergreen.V207.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V207.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V207.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V207.Id.Id Evergreen.V207.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V207.EmailAddress.EmailAddress (Result Evergreen.V207.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V207.EmailAddress.EmailAddress (Result Evergreen.V207.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Evergreen.V207.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V207.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMaybeMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Result Evergreen.V207.Discord.HttpError Evergreen.V207.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V207.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Result Evergreen.V207.Discord.HttpError Evergreen.V207.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Result Evergreen.V207.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Result Evergreen.V207.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Result Evergreen.V207.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Result Evergreen.V207.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji (Result Evergreen.V207.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji (Result Evergreen.V207.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji (Result Evergreen.V207.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) Evergreen.V207.Emoji.Emoji (Result Evergreen.V207.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V207.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V207.Discord.HttpError (List ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId, Maybe Evergreen.V207.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V207.Slack.CurrentUser
            , team : Evergreen.V207.Slack.Team
            , users : List Evergreen.V207.Slack.User
            , channels : List ( Evergreen.V207.Slack.Channel, List Evergreen.V207.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Result Effect.Http.Error Evergreen.V207.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) Evergreen.V207.Discord.UserAuth (Result Evergreen.V207.Discord.HttpError Evergreen.V207.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Result Evergreen.V207.Discord.HttpError Evergreen.V207.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
        (Result
            Evergreen.V207.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId
                , members : List (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
                }
            , List
                ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId
                , { guild : Evergreen.V207.Discord.GatewayGuild
                  , channels : List Evergreen.V207.Discord.Channel
                  , icon : Maybe Evergreen.V207.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V207.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.AttachmentId, Evergreen.V207.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V207.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V207.Discord.Id Evergreen.V207.Discord.AttachmentId, Evergreen.V207.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V207.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V207.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V207.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V207.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) (Result Evergreen.V207.Discord.HttpError (List Evergreen.V207.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Result Evergreen.V207.Discord.HttpError (List Evergreen.V207.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V207.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V207.DmChannel.DmChannelId Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V207.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) Evergreen.V207.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V207.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V207.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
        (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V207.Discord.HttpError
            { guild : Evergreen.V207.Discord.GatewayGuild
            , channels : List Evergreen.V207.Discord.Channel
            , icon : Maybe Evergreen.V207.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId) (Result Evergreen.V207.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V207.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (List ( Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId, Result Effect.Http.Error Evergreen.V207.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V207.Id.Id Evergreen.V207.Id.StickerId, Result Effect.Http.Error Evergreen.V207.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V207.Discord.HttpError (List Evergreen.V207.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V207.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V207.SecretId.SecretId Evergreen.V207.SecretId.ServerSecret))
