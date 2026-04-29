module Evergreen.V209.Types exposing (..)

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
import Evergreen.V209.AiChat
import Evergreen.V209.ChannelName
import Evergreen.V209.Coord
import Evergreen.V209.CssPixels
import Evergreen.V209.Discord
import Evergreen.V209.DiscordAttachmentId
import Evergreen.V209.DiscordUserData
import Evergreen.V209.DmChannel
import Evergreen.V209.Editable
import Evergreen.V209.EmailAddress
import Evergreen.V209.Embed
import Evergreen.V209.Emoji
import Evergreen.V209.FileStatus
import Evergreen.V209.GuildName
import Evergreen.V209.Id
import Evergreen.V209.ImageEditor
import Evergreen.V209.Local
import Evergreen.V209.LocalState
import Evergreen.V209.Log
import Evergreen.V209.LoginForm
import Evergreen.V209.MembersAndOwner
import Evergreen.V209.Message
import Evergreen.V209.MessageInput
import Evergreen.V209.MessageView
import Evergreen.V209.NonemptyDict
import Evergreen.V209.NonemptySet
import Evergreen.V209.OneToOne
import Evergreen.V209.Pages.Admin
import Evergreen.V209.Pagination
import Evergreen.V209.PersonName
import Evergreen.V209.Ports
import Evergreen.V209.Postmark
import Evergreen.V209.Range
import Evergreen.V209.RichText
import Evergreen.V209.Route
import Evergreen.V209.SecretId
import Evergreen.V209.SessionIdHash
import Evergreen.V209.Slack
import Evergreen.V209.Sticker
import Evergreen.V209.TextEditor
import Evergreen.V209.ToBackendLog
import Evergreen.V209.Touch
import Evergreen.V209.TwoFactorAuthentication
import Evergreen.V209.Ui.Anim
import Evergreen.V209.Untrusted
import Evergreen.V209.User
import Evergreen.V209.UserAgent
import Evergreen.V209.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V209.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V209.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.LocalState.DiscordFrontendGuild
    , user : Evergreen.V209.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V209.SessionIdHash.SessionIdHash Evergreen.V209.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V209.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V209.Route.Route
    , windowSize : Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V209.Ports.NotificationPermission
    , pwaStatus : Evergreen.V209.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V209.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V209.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V209.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V209.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V209.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V209.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V209.GuildName.GuildName (Evergreen.V209.UserSession.ToBeFilledInByBackend (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Local_RemoveReactionEmoji Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V209.Id.GuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V209.Id.DiscordGuildOrDmId_DmData (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V209.UserSession.SetViewing
    | Local_SetName Evergreen.V209.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V209.Id.GuildOrDmId (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V209.Id.GuildOrDmId (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V209.Id.DiscordGuildOrDmId (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V209.Id.DiscordGuildOrDmId (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.Message.Message Evergreen.V209.Id.ThreadMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V209.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V209.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V209.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V209.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V209.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V209.Emoji.SkinTone)


type ServerChange
    = Server_SendMessage (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Effect.Time.Posix Evergreen.V209.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))) Evergreen.V209.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V209.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))) Evergreen.V209.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V209.LocalState.JoinGuildError
            { guildId : Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId
            , guild : Evergreen.V209.LocalState.FrontendGuild
            , owner : Evergreen.V209.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.GuildOrDmId Evergreen.V209.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.GuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Server_RemoveReactionEmoji (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.GuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Emoji.Emoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.Emoji.Emoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Emoji.Emoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.GuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))) (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V209.Id.DiscordGuildOrDmId_DmData (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V209.SessionIdHash.SessionIdHash Evergreen.V209.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V209.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V209.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V209.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.ChannelName.ChannelName (Evergreen.V209.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)
        (Evergreen.V209.NonemptyDict.NonemptyDict
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Maybe (Evergreen.V209.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V209.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V209.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V209.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V209.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V209.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V209.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (Evergreen.V209.Discord.OptionalData String) (Evergreen.V209.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
        (Evergreen.V209.MembersAndOwner.MembersAndOwner
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData)


type LocalMsg
    = LocalChange (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V209.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V209.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V209.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V209.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels) (Maybe Evergreen.V209.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId) (Evergreen.V209.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V209.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V209.Local.Local LocalMsg Evergreen.V209.LocalState.LocalState
    , admin : Evergreen.V209.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId, Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V209.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V209.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V209.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.NonemptyDict.NonemptyDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V209.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V209.TextEditor.Model
    , profilePictureEditor : Evergreen.V209.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V209.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V209.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V209.Range.Range
                , direction : Evergreen.V209.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V209.NonemptyDict.NonemptyDict Int Evergreen.V209.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V209.NonemptyDict.NonemptyDict Int Evergreen.V209.Touch.Touch
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
    | AdminToFrontend Evergreen.V209.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V209.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V209.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V209.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V209.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V209.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V209.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V209.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V209.Ports.NotificationPermission
    , pwaStatus : Evergreen.V209.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V209.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V209.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V209.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V209.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V209.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V209.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V209.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId, Evergreen.V209.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V209.DmChannel.DmChannelId, Evergreen.V209.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId, Evergreen.V209.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId, Evergreen.V209.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V209.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V209.NonemptyDict.NonemptyDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V209.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V209.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V209.LocalState.LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V209.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V209.DmChannel.DmChannelId Evergreen.V209.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) Evergreen.V209.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Slack.Id Evergreen.V209.Slack.ChannelId) Evergreen.V209.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V209.OneToOne.OneToOne String (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    , slackUsers : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Slack.Id Evergreen.V209.Slack.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    , slackServers : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Slack.Id Evergreen.V209.Slack.TeamId) (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    , slackToken : Maybe Evergreen.V209.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V209.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V209.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V209.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V209.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId, Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V209.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V209.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V209.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V209.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.LocalState.LoadingDiscordChannel (List Evergreen.V209.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V209.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId) Evergreen.V209.Sticker.StickerData
    , discordStickers : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Discord.Id Evergreen.V209.Discord.StickerId) (Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId)
    , postmarkApiKey : Evergreen.V209.Postmark.ApiKey
    , serverSecret : Evergreen.V209.SecretId.SecretId Evergreen.V209.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V209.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V209.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V209.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V209.Route.Route
    | SelectedFilesToAttach ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V209.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V209.Emoji.Emoji
    | MessageMenu_PressedEditMessage Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V209.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V209.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V209.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V209.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V209.NonemptyDict.NonemptyDict Int Evergreen.V209.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V209.NonemptyDict.NonemptyDict Int Evergreen.V209.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V209.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V209.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V209.Editable.Msg Evergreen.V209.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V209.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V209.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
        { fileId : Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute )
        { fileId : Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V209.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V209.Id.AnyGuildOrDmId, Evergreen.V209.Id.ThreadRoute ) (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRouteWithMessage Evergreen.V209.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V209.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V209.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) Evergreen.V209.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) Evergreen.V209.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V209.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V209.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId
        , otherUserId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V209.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRoute Evergreen.V209.MessageInput.Msg
    | MessageInputMsg Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRoute Evergreen.V209.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V209.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V209.Range.Range, Evergreen.V209.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V209.Range.Range, Evergreen.V209.Range.SelectionDirection ) )


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V209.Id.AnyGuildOrDmId Evergreen.V209.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V209.Id.Id Evergreen.V209.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V209.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V209.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V209.Untrusted.Untrusted Evergreen.V209.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V209.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V209.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V209.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V209.PersonName.PersonName Evergreen.V209.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V209.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V209.Slack.OAuthCode Evergreen.V209.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V209.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V209.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V209.Id.Id Evergreen.V209.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V209.EmailAddress.EmailAddress (Result Evergreen.V209.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V209.EmailAddress.EmailAddress (Result Evergreen.V209.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Evergreen.V209.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V209.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMaybeMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Result Evergreen.V209.Discord.HttpError Evergreen.V209.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V209.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Result Evergreen.V209.Discord.HttpError Evergreen.V209.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Result Evergreen.V209.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Result Evergreen.V209.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Result Evergreen.V209.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Result Evergreen.V209.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji (Result Evergreen.V209.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji (Result Evergreen.V209.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji (Result Evergreen.V209.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) Evergreen.V209.Emoji.Emoji (Result Evergreen.V209.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V209.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V209.Discord.HttpError (List ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId, Maybe Evergreen.V209.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V209.Slack.CurrentUser
            , team : Evergreen.V209.Slack.Team
            , users : List Evergreen.V209.Slack.User
            , channels : List ( Evergreen.V209.Slack.Channel, List Evergreen.V209.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Result Effect.Http.Error Evergreen.V209.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Discord.UserAuth (Result Evergreen.V209.Discord.HttpError Evergreen.V209.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Result Evergreen.V209.Discord.HttpError Evergreen.V209.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
        (Result
            Evergreen.V209.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId
                , members : List (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
                }
            , List
                ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId
                , { guild : Evergreen.V209.Discord.GatewayGuild
                  , channels : List Evergreen.V209.Discord.Channel
                  , icon : Maybe Evergreen.V209.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V209.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.AttachmentId, Evergreen.V209.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V209.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V209.Discord.Id Evergreen.V209.Discord.AttachmentId, Evergreen.V209.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V209.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V209.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V209.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V209.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) (Result Evergreen.V209.Discord.HttpError (List Evergreen.V209.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Result Evergreen.V209.Discord.HttpError (List Evergreen.V209.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V209.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V209.DmChannel.DmChannelId Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V209.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) Evergreen.V209.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V209.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V209.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
        (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V209.Discord.HttpError
            { guild : Evergreen.V209.Discord.GatewayGuild
            , channels : List Evergreen.V209.Discord.Channel
            , icon : Maybe Evergreen.V209.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId) (Result Evergreen.V209.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V209.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (List ( Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId, Result Effect.Http.Error Evergreen.V209.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V209.Id.Id Evergreen.V209.Id.StickerId, Result Effect.Http.Error Evergreen.V209.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V209.Discord.HttpError (List Evergreen.V209.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V209.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V209.SecretId.SecretId Evergreen.V209.SecretId.ServerSecret))
