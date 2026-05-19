module Evergreen.V239.Types exposing (..)

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
import Evergreen.V239.AiChat
import Evergreen.V239.Call
import Evergreen.V239.ChannelDescription
import Evergreen.V239.ChannelName
import Evergreen.V239.Coord
import Evergreen.V239.CssPixels
import Evergreen.V239.CustomEmoji
import Evergreen.V239.Discord
import Evergreen.V239.DiscordAttachmentId
import Evergreen.V239.DiscordUserData
import Evergreen.V239.DmChannel
import Evergreen.V239.Editable
import Evergreen.V239.EmailAddress
import Evergreen.V239.Embed
import Evergreen.V239.Emoji
import Evergreen.V239.FileStatus
import Evergreen.V239.Go
import Evergreen.V239.GuildName
import Evergreen.V239.Id
import Evergreen.V239.ImageEditor
import Evergreen.V239.Local
import Evergreen.V239.LocalState
import Evergreen.V239.Log
import Evergreen.V239.LoginForm
import Evergreen.V239.MembersAndOwner
import Evergreen.V239.Message
import Evergreen.V239.MessageInput
import Evergreen.V239.MessageView
import Evergreen.V239.NonemptyDict
import Evergreen.V239.NonemptySet
import Evergreen.V239.OneToOne
import Evergreen.V239.Pages.Admin
import Evergreen.V239.Pagination
import Evergreen.V239.PersonName
import Evergreen.V239.Ports
import Evergreen.V239.Postmark
import Evergreen.V239.Range
import Evergreen.V239.RichText
import Evergreen.V239.Route
import Evergreen.V239.SecretId
import Evergreen.V239.SessionIdHash
import Evergreen.V239.Slack
import Evergreen.V239.Sticker
import Evergreen.V239.TextEditor
import Evergreen.V239.ToBackendLog
import Evergreen.V239.Touch
import Evergreen.V239.TwoFactorAuthentication
import Evergreen.V239.Ui.Anim
import Evergreen.V239.Untrusted
import Evergreen.V239.User
import Evergreen.V239.UserAgent
import Evergreen.V239.UserSession
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V239.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V239.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.LocalState.DiscordFrontendGuild
    , user : Evergreen.V239.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V239.SessionIdHash.SessionIdHash Evergreen.V239.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V239.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId) Evergreen.V239.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V239.Call.RoomId (Evergreen.V239.NonemptySet.NonemptySet ( Evergreen.V239.Id.Id Evergreen.V239.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V239.Route.Route
    , windowSize : Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V239.Ports.NotificationPermission
    , pwaStatus : Evergreen.V239.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V239.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V239.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V239.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V239.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V239.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V239.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.ChannelName.ChannelName Evergreen.V239.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.ChannelName.ChannelName Evergreen.V239.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId)
    | Local_DeleteGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V239.GuildName.GuildName (Evergreen.V239.UserSession.ToBeFilledInByBackend (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V239.Id.GuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V239.Id.DiscordGuildOrDmId_DmData (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V239.UserSession.SetViewing
    | Local_SetName Evergreen.V239.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V239.Id.GuildOrDmId (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V239.Id.GuildOrDmId (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V239.Id.DiscordGuildOrDmId (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V239.Id.DiscordGuildOrDmId (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.Message.Message Evergreen.V239.Id.ThreadMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V239.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V239.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V239.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V239.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V239.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V239.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V239.NonemptySet.NonemptySet (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V239.Call.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        }
        Evergreen.V239.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Effect.Time.Posix Evergreen.V239.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))) Evergreen.V239.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V239.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))) Evergreen.V239.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.ChannelName.ChannelName Evergreen.V239.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.ChannelName.ChannelName Evergreen.V239.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId)
    | Server_DeleteGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V239.LocalState.JoinGuildError
            { guildId : Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId
            , guild : Evergreen.V239.LocalState.FrontendGuild
            , owner : Evergreen.V239.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.GuildOrDmId Evergreen.V239.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.GuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.GuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.GuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))) (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V239.Id.DiscordGuildOrDmId_DmData (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.FileStatus.FileHash
    | Server_SetGuildIcon (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V239.SessionIdHash.SessionIdHash Evergreen.V239.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V239.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V239.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V239.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.ChannelName.ChannelName (Evergreen.V239.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)
        (Evergreen.V239.NonemptyDict.NonemptyDict
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Maybe (Evergreen.V239.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V239.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V239.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V239.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V239.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V239.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V239.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (Evergreen.V239.Discord.OptionalData String) (Evergreen.V239.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
        (Evergreen.V239.MembersAndOwner.MembersAndOwner
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId) Evergreen.V239.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V239.Call.ServerChange
    | Server_Go
        (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
        { otherUserId : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        }
        Evergreen.V239.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) LocalChange
    | ServerChange ServerChange


type alias NewChannelForm =
    { name : String
    , description : String
    , pressedSubmit : Bool
    }


type alias EditChannelForm =
    { name : String
    , description : String
    , deleteConfirmation : String
    , showDeleteConfirmation : Bool
    , pressedSubmit : Bool
    }


type alias EditGuildForm =
    { deleteConfirmation : String
    , showDeleteConfirmation : Bool
    }


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V239.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V239.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V239.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V239.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels) (Maybe Evergreen.V239.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId) (Evergreen.V239.NonemptySet.NonemptySet Int))
    }


type alias UserOptionsModel =
    { name : Evergreen.V239.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V239.Local.Local LocalMsg Evergreen.V239.LocalState.LocalState
    , admin : Evergreen.V239.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId, Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId ) EditChannelForm
    , editGuildForm : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) EditGuildForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V239.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V239.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : Evergreen.V239.Call.ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V239.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.NonemptyDict.NonemptyDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V239.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V239.TextEditor.Model
    , profilePictureEditor : Evergreen.V239.ImageEditor.Model
    , guildIconEditor : Maybe ( Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId, Evergreen.V239.ImageEditor.Model )
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V239.Emoji.Model
    , voiceChat : Evergreen.V239.Call.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V239.Id.Id Evergreen.V239.Id.UserId, Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) ) Evergreen.V239.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V239.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V239.Range.Range
                , direction : Evergreen.V239.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V239.NonemptyDict.NonemptyDict Int Evergreen.V239.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V239.NonemptyDict.NonemptyDict Int Evergreen.V239.Touch.Touch
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
    | AdminToFrontend Evergreen.V239.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V239.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V239.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V239.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V239.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V239.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V239.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V239.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V239.Ports.NotificationPermission
    , pwaStatus : Evergreen.V239.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V239.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V239.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V239.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V239.Id.Id Evergreen.V239.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V239.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V239.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V239.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V239.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId, Evergreen.V239.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V239.DmChannel.DmChannelId, Evergreen.V239.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId, Evergreen.V239.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId, Evergreen.V239.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V239.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V239.NonemptyDict.NonemptyDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V239.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V239.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V239.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V239.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , nextGuildId : Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId
    , guilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.LocalState.BackendGuild
    , deletedGuilds : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.LocalState.DeletedBackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V239.DmChannel.DmChannelId Evergreen.V239.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) Evergreen.V239.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Slack.Id Evergreen.V239.Slack.ChannelId) Evergreen.V239.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V239.OneToOne.OneToOne String (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    , slackUsers : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Slack.Id Evergreen.V239.Slack.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    , slackServers : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Slack.Id Evergreen.V239.Slack.TeamId) (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    , slackToken : Maybe Evergreen.V239.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V239.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V239.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V239.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V239.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId, Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V239.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V239.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V239.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V239.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.LocalState.LoadingDiscordChannel (List Evergreen.V239.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V239.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId) Evergreen.V239.Sticker.StickerData
    , discordStickers : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Discord.Id Evergreen.V239.Discord.StickerId) (Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId) Evergreen.V239.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V239.OneToOne.OneToOne Evergreen.V239.RichText.DiscordCustomEmojiIdAndName (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V239.Postmark.ApiKey
    , serverSecret : Evergreen.V239.SecretId.SecretId Evergreen.V239.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V239.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V239.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V239.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V239.Route.Route
    | SelectedFilesToAttach ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId)
    | EditGuildFormChanged (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) EditGuildForm
    | PressedDeleteGuild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | PressedCreateInviteLink (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V239.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V239.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V239.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V239.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V239.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V239.NonemptyDict.NonemptyDict Int Evergreen.V239.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V239.NonemptyDict.NonemptyDict Int Evergreen.V239.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V239.NonemptySet.NonemptySet (Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V239.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V239.AiChat.Msg
    | GoMsg Evergreen.V239.Go.Msg
    | UserNameEditableMsg (Evergreen.V239.Editable.Msg Evergreen.V239.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V239.ImageEditor.Msg
    | GuildIconEditorMsg (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
        { fileId : Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute )
        { fileId : Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V239.Id.AnyGuildOrDmId, Evergreen.V239.Id.ThreadRoute ) (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRouteWithMessage Evergreen.V239.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V239.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V239.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) Evergreen.V239.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) Evergreen.V239.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V239.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V239.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId
        , otherUserId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRoute Evergreen.V239.MessageInput.Msg
    | MessageInputMsg Evergreen.V239.Id.AnyGuildOrDmId Evergreen.V239.Id.ThreadRoute Evergreen.V239.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V239.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V239.Range.Range, Evergreen.V239.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V239.Range.Range, Evergreen.V239.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V239.Call.FromJs)
    | VoiceChatMsg Evergreen.V239.Call.Msg
    | PressedChannelHeaderTab Evergreen.V239.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V239.DmChannel.DmChannelId Evergreen.V239.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V239.Id.DiscordGuildOrDmId Evergreen.V239.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V239.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V239.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V239.Untrusted.Untrusted Evergreen.V239.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V239.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V239.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V239.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V239.PersonName.PersonName Evergreen.V239.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V239.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V239.Slack.OAuthCode Evergreen.V239.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V239.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V239.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V239.EmailAddress.EmailAddress (Result Evergreen.V239.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V239.EmailAddress.EmailAddress (Result Evergreen.V239.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Evergreen.V239.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V239.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMaybeMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Result Evergreen.V239.Discord.HttpError Evergreen.V239.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V239.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Result Evergreen.V239.Discord.HttpError Evergreen.V239.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Result Evergreen.V239.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Result Evergreen.V239.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Result Evergreen.V239.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Result Evergreen.V239.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji (Result Evergreen.V239.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji (Result Evergreen.V239.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji (Result Evergreen.V239.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) Evergreen.V239.Emoji.EmojiOrCustomEmoji (Result Evergreen.V239.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V239.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V239.Discord.HttpError (List ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId, Maybe Evergreen.V239.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V239.Slack.CurrentUser
            , team : Evergreen.V239.Slack.Team
            , users : List Evergreen.V239.Slack.User
            , channels : List ( Evergreen.V239.Slack.Channel, List Evergreen.V239.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Result Effect.Http.Error Evergreen.V239.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Discord.UserAuth (Result Evergreen.V239.Discord.HttpError Evergreen.V239.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Result Evergreen.V239.Discord.HttpError Evergreen.V239.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
        (Result
            Evergreen.V239.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId
                , members : List (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
                }
            , List
                ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId
                , { guild : Evergreen.V239.Discord.GatewayGuild
                  , channels : List Evergreen.V239.Discord.Channel
                  , icon : Maybe Evergreen.V239.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V239.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.AttachmentId, Evergreen.V239.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V239.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V239.Discord.Id Evergreen.V239.Discord.AttachmentId, Evergreen.V239.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V239.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V239.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V239.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V239.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) (Result Evergreen.V239.Discord.HttpError (List Evergreen.V239.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Result Evergreen.V239.Discord.HttpError (List Evergreen.V239.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V239.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V239.DmChannel.DmChannelId Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V239.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) Evergreen.V239.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V239.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V239.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
        (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V239.Discord.HttpError
            { guild : Evergreen.V239.Discord.GatewayGuild
            , channels : List Evergreen.V239.Discord.Channel
            , icon : Maybe Evergreen.V239.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId) (Result Evergreen.V239.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V239.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (List ( Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId, Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V239.Id.Id Evergreen.V239.Id.StickerId, Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (List ( Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V239.Id.Id Evergreen.V239.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V239.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V239.Discord.HttpError (List Evergreen.V239.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V239.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V239.SecretId.SecretId Evergreen.V239.SecretId.ServerSecret))
