module Evergreen.V217.Types exposing (..)

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
import Evergreen.V217.AiChat
import Evergreen.V217.ChannelName
import Evergreen.V217.Coord
import Evergreen.V217.CssPixels
import Evergreen.V217.CustomEmoji
import Evergreen.V217.Discord
import Evergreen.V217.DiscordAttachmentId
import Evergreen.V217.DiscordUserData
import Evergreen.V217.DmChannel
import Evergreen.V217.Editable
import Evergreen.V217.EmailAddress
import Evergreen.V217.Embed
import Evergreen.V217.Emoji
import Evergreen.V217.FileStatus
import Evergreen.V217.Go
import Evergreen.V217.GuildName
import Evergreen.V217.Id
import Evergreen.V217.ImageEditor
import Evergreen.V217.Local
import Evergreen.V217.LocalState
import Evergreen.V217.Log
import Evergreen.V217.LoginForm
import Evergreen.V217.MembersAndOwner
import Evergreen.V217.Message
import Evergreen.V217.MessageInput
import Evergreen.V217.MessageView
import Evergreen.V217.NonemptyDict
import Evergreen.V217.NonemptySet
import Evergreen.V217.OneToOne
import Evergreen.V217.Pages.Admin
import Evergreen.V217.Pagination
import Evergreen.V217.PersonName
import Evergreen.V217.Ports
import Evergreen.V217.Postmark
import Evergreen.V217.Range
import Evergreen.V217.RichText
import Evergreen.V217.Route
import Evergreen.V217.SecretId
import Evergreen.V217.SessionIdHash
import Evergreen.V217.Slack
import Evergreen.V217.Sticker
import Evergreen.V217.TextEditor
import Evergreen.V217.ToBackendLog
import Evergreen.V217.Touch
import Evergreen.V217.TwoFactorAuthentication
import Evergreen.V217.Ui.Anim
import Evergreen.V217.Untrusted
import Evergreen.V217.User
import Evergreen.V217.UserAgent
import Evergreen.V217.UserSession
import Evergreen.V217.VoiceChat
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V217.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V217.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.LocalState.DiscordFrontendGuild
    , user : Evergreen.V217.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V217.SessionIdHash.SessionIdHash Evergreen.V217.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V217.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId) Evergreen.V217.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V217.VoiceChat.RoomId (Evergreen.V217.NonemptySet.NonemptySet ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V217.Route.Route
    , windowSize : Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V217.Ports.NotificationPermission
    , pwaStatus : Evergreen.V217.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V217.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V217.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V217.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V217.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V217.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V217.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V217.GuildName.GuildName (Evergreen.V217.UserSession.ToBeFilledInByBackend (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V217.Id.GuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V217.Id.DiscordGuildOrDmId_DmData (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V217.UserSession.SetViewing
    | Local_SetName Evergreen.V217.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V217.Id.GuildOrDmId (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V217.Id.GuildOrDmId (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V217.Id.DiscordGuildOrDmId (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V217.Id.DiscordGuildOrDmId (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.Message.Message Evergreen.V217.Id.ThreadMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V217.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V217.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V217.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V217.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V217.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V217.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V217.NonemptySet.NonemptySet (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V217.VoiceChat.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        }
        Evergreen.V217.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Effect.Time.Posix Evergreen.V217.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))) Evergreen.V217.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V217.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))) Evergreen.V217.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V217.LocalState.JoinGuildError
            { guildId : Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId
            , guild : Evergreen.V217.LocalState.FrontendGuild
            , owner : Evergreen.V217.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.GuildOrDmId Evergreen.V217.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.GuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.GuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.GuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))) (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V217.Id.DiscordGuildOrDmId_DmData (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V217.SessionIdHash.SessionIdHash Evergreen.V217.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V217.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V217.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V217.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.ChannelName.ChannelName (Evergreen.V217.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)
        (Evergreen.V217.NonemptyDict.NonemptyDict
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Maybe (Evergreen.V217.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V217.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V217.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V217.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V217.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V217.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V217.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (Evergreen.V217.Discord.OptionalData String) (Evergreen.V217.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
        (Evergreen.V217.MembersAndOwner.MembersAndOwner
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId) Evergreen.V217.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V217.VoiceChat.ServerChange
    | Server_Go
        (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
        { otherUserId : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        }
        Evergreen.V217.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V217.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V217.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V217.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V217.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels) (Maybe Evergreen.V217.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId) (Evergreen.V217.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V217.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V217.Local.Local LocalMsg Evergreen.V217.LocalState.LocalState
    , admin : Evergreen.V217.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId, Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V217.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V217.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V217.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.NonemptyDict.NonemptyDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V217.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V217.TextEditor.Model
    , profilePictureEditor : Evergreen.V217.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V217.Emoji.Model
    , voiceChat : Evergreen.V217.VoiceChat.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) ) Evergreen.V217.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V217.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V217.Range.Range
                , direction : Evergreen.V217.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V217.NonemptyDict.NonemptyDict Int Evergreen.V217.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V217.NonemptyDict.NonemptyDict Int Evergreen.V217.Touch.Touch
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
    | AdminToFrontend Evergreen.V217.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V217.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V217.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V217.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V217.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V217.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V217.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V217.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V217.Ports.NotificationPermission
    , pwaStatus : Evergreen.V217.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V217.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V217.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V217.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V217.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V217.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V217.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V217.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId, Evergreen.V217.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V217.DmChannel.DmChannelId, Evergreen.V217.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId, Evergreen.V217.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId, Evergreen.V217.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V217.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V217.NonemptyDict.NonemptyDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V217.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V217.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V217.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V217.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V217.DmChannel.DmChannelId Evergreen.V217.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) Evergreen.V217.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Slack.Id Evergreen.V217.Slack.ChannelId) Evergreen.V217.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V217.OneToOne.OneToOne String (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    , slackUsers : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Slack.Id Evergreen.V217.Slack.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    , slackServers : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Slack.Id Evergreen.V217.Slack.TeamId) (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    , slackToken : Maybe Evergreen.V217.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V217.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V217.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V217.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V217.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId, Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V217.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V217.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V217.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V217.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.LocalState.LoadingDiscordChannel (List Evergreen.V217.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V217.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId) Evergreen.V217.Sticker.StickerData
    , discordStickers : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Discord.Id Evergreen.V217.Discord.StickerId) (Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId) Evergreen.V217.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V217.OneToOne.OneToOne Evergreen.V217.RichText.DiscordCustomEmojiIdAndName (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V217.Postmark.ApiKey
    , serverSecret : Evergreen.V217.SecretId.SecretId Evergreen.V217.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V217.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V217.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V217.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V217.Route.Route
    | SelectedFilesToAttach ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V217.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V217.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V217.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V217.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V217.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V217.NonemptyDict.NonemptyDict Int Evergreen.V217.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V217.NonemptyDict.NonemptyDict Int Evergreen.V217.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V217.NonemptySet.NonemptySet (Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V217.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V217.AiChat.Msg
    | GoMsg Evergreen.V217.Go.Msg
    | UserNameEditableMsg (Evergreen.V217.Editable.Msg Evergreen.V217.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V217.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
        { fileId : Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute )
        { fileId : Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V217.Id.AnyGuildOrDmId, Evergreen.V217.Id.ThreadRoute ) (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRouteWithMessage Evergreen.V217.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V217.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V217.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) Evergreen.V217.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) Evergreen.V217.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V217.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V217.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId
        , otherUserId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRoute Evergreen.V217.MessageInput.Msg
    | MessageInputMsg Evergreen.V217.Id.AnyGuildOrDmId Evergreen.V217.Id.ThreadRoute Evergreen.V217.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V217.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V217.Range.Range, Evergreen.V217.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V217.Range.Range, Evergreen.V217.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V217.VoiceChat.FromJs)
    | GotVoiceChatRecording Bytes.Bytes
    | VoiceChatMsg Evergreen.V217.VoiceChat.Msg
    | PressedChannelHeaderTab Evergreen.V217.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V217.DmChannel.DmChannelId Evergreen.V217.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V217.Id.DiscordGuildOrDmId Evergreen.V217.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V217.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V217.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V217.Untrusted.Untrusted Evergreen.V217.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V217.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V217.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V217.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V217.PersonName.PersonName Evergreen.V217.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V217.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V217.Slack.OAuthCode Evergreen.V217.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V217.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V217.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V217.EmailAddress.EmailAddress (Result Evergreen.V217.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V217.EmailAddress.EmailAddress (Result Evergreen.V217.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Evergreen.V217.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V217.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMaybeMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Result Evergreen.V217.Discord.HttpError Evergreen.V217.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V217.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Result Evergreen.V217.Discord.HttpError Evergreen.V217.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Result Evergreen.V217.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Result Evergreen.V217.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Result Evergreen.V217.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Result Evergreen.V217.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji (Result Evergreen.V217.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji (Result Evergreen.V217.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji (Result Evergreen.V217.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) Evergreen.V217.Emoji.EmojiOrCustomEmoji (Result Evergreen.V217.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V217.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V217.Discord.HttpError (List ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId, Maybe Evergreen.V217.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V217.Slack.CurrentUser
            , team : Evergreen.V217.Slack.Team
            , users : List Evergreen.V217.Slack.User
            , channels : List ( Evergreen.V217.Slack.Channel, List Evergreen.V217.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Result Effect.Http.Error Evergreen.V217.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Discord.UserAuth (Result Evergreen.V217.Discord.HttpError Evergreen.V217.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Result Evergreen.V217.Discord.HttpError Evergreen.V217.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
        (Result
            Evergreen.V217.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId
                , members : List (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
                }
            , List
                ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId
                , { guild : Evergreen.V217.Discord.GatewayGuild
                  , channels : List Evergreen.V217.Discord.Channel
                  , icon : Maybe Evergreen.V217.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V217.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.AttachmentId, Evergreen.V217.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V217.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V217.Discord.Id Evergreen.V217.Discord.AttachmentId, Evergreen.V217.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V217.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V217.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V217.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V217.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) (Result Evergreen.V217.Discord.HttpError (List Evergreen.V217.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Result Evergreen.V217.Discord.HttpError (List Evergreen.V217.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V217.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V217.DmChannel.DmChannelId Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V217.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) Evergreen.V217.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V217.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V217.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
        (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V217.Discord.HttpError
            { guild : Evergreen.V217.Discord.GatewayGuild
            , channels : List Evergreen.V217.Discord.Channel
            , icon : Maybe Evergreen.V217.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId) (Result Evergreen.V217.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V217.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (List ( Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId, Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V217.Id.Id Evergreen.V217.Id.StickerId, Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (List ( Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V217.Id.Id Evergreen.V217.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V217.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V217.Discord.HttpError (List Evergreen.V217.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V217.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V217.SecretId.SecretId Evergreen.V217.SecretId.ServerSecret))
