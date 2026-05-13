module Evergreen.V215.Types exposing (..)

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
import Evergreen.V215.AiChat
import Evergreen.V215.ChannelName
import Evergreen.V215.Coord
import Evergreen.V215.CssPixels
import Evergreen.V215.CustomEmoji
import Evergreen.V215.Discord
import Evergreen.V215.DiscordAttachmentId
import Evergreen.V215.DiscordUserData
import Evergreen.V215.DmChannel
import Evergreen.V215.Editable
import Evergreen.V215.EmailAddress
import Evergreen.V215.Embed
import Evergreen.V215.Emoji
import Evergreen.V215.FileStatus
import Evergreen.V215.GuildName
import Evergreen.V215.Id
import Evergreen.V215.ImageEditor
import Evergreen.V215.Local
import Evergreen.V215.LocalState
import Evergreen.V215.Log
import Evergreen.V215.LoginForm
import Evergreen.V215.MembersAndOwner
import Evergreen.V215.Message
import Evergreen.V215.MessageInput
import Evergreen.V215.MessageView
import Evergreen.V215.NonemptyDict
import Evergreen.V215.NonemptySet
import Evergreen.V215.OneToOne
import Evergreen.V215.Pages.Admin
import Evergreen.V215.Pages.Go
import Evergreen.V215.Pagination
import Evergreen.V215.PersonName
import Evergreen.V215.Ports
import Evergreen.V215.Postmark
import Evergreen.V215.Range
import Evergreen.V215.RichText
import Evergreen.V215.Route
import Evergreen.V215.SecretId
import Evergreen.V215.SessionIdHash
import Evergreen.V215.Slack
import Evergreen.V215.Sticker
import Evergreen.V215.TextEditor
import Evergreen.V215.ToBackendLog
import Evergreen.V215.Touch
import Evergreen.V215.TwoFactorAuthentication
import Evergreen.V215.Ui.Anim
import Evergreen.V215.Untrusted
import Evergreen.V215.User
import Evergreen.V215.UserAgent
import Evergreen.V215.UserSession
import Evergreen.V215.VoiceChat
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V215.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V215.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.LocalState.DiscordFrontendGuild
    , user : Evergreen.V215.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V215.SessionIdHash.SessionIdHash Evergreen.V215.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V215.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId) Evergreen.V215.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V215.VoiceChat.RoomId (Evergreen.V215.NonemptySet.NonemptySet ( Evergreen.V215.Id.Id Evergreen.V215.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V215.Route.Route
    , windowSize : Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V215.Ports.NotificationPermission
    , pwaStatus : Evergreen.V215.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V215.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V215.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V215.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V215.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V215.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V215.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V215.GuildName.GuildName (Evergreen.V215.UserSession.ToBeFilledInByBackend (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V215.Id.GuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V215.Id.DiscordGuildOrDmId_DmData (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V215.UserSession.SetViewing
    | Local_SetName Evergreen.V215.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V215.Id.GuildOrDmId (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V215.Id.GuildOrDmId (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V215.Id.DiscordGuildOrDmId (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V215.Id.DiscordGuildOrDmId (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.Message.Message Evergreen.V215.Id.ThreadMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V215.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V215.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V215.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V215.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V215.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V215.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V215.NonemptySet.NonemptySet (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V215.VoiceChat.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Effect.Time.Posix Evergreen.V215.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))) Evergreen.V215.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V215.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))) Evergreen.V215.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V215.LocalState.JoinGuildError
            { guildId : Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId
            , guild : Evergreen.V215.LocalState.FrontendGuild
            , owner : Evergreen.V215.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.GuildOrDmId Evergreen.V215.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.GuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.GuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.GuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))) (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V215.Id.DiscordGuildOrDmId_DmData (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V215.SessionIdHash.SessionIdHash Evergreen.V215.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V215.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V215.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V215.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.ChannelName.ChannelName (Evergreen.V215.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)
        (Evergreen.V215.NonemptyDict.NonemptyDict
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Maybe (Evergreen.V215.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V215.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V215.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V215.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V215.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V215.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V215.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (Evergreen.V215.Discord.OptionalData String) (Evergreen.V215.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
        (Evergreen.V215.MembersAndOwner.MembersAndOwner
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId) Evergreen.V215.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V215.VoiceChat.ServerChange


type LocalMsg
    = LocalChange (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V215.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V215.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V215.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V215.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels) (Maybe Evergreen.V215.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId) (Evergreen.V215.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V215.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V215.Local.Local LocalMsg Evergreen.V215.LocalState.LocalState
    , admin : Evergreen.V215.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId, Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V215.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V215.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V215.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.NonemptyDict.NonemptyDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V215.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V215.TextEditor.Model
    , profilePictureEditor : Evergreen.V215.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V215.Emoji.Model
    , voiceChat : Evergreen.V215.VoiceChat.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V215.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V215.Range.Range
                , direction : Evergreen.V215.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V215.NonemptyDict.NonemptyDict Int Evergreen.V215.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V215.NonemptyDict.NonemptyDict Int Evergreen.V215.Touch.Touch
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
    | AdminToFrontend Evergreen.V215.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V215.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V215.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V215.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V215.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V215.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V215.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V215.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V215.Ports.NotificationPermission
    , pwaStatus : Evergreen.V215.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V215.AiChat.FrontendModel
    , goModel : Evergreen.V215.Pages.Go.Model
    , scrollbarWidth : Int
    , userAgent : Evergreen.V215.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V215.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V215.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V215.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V215.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V215.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId, Evergreen.V215.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V215.DmChannel.DmChannelId, Evergreen.V215.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId, Evergreen.V215.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId, Evergreen.V215.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V215.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V215.NonemptyDict.NonemptyDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V215.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V215.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V215.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V215.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V215.DmChannel.DmChannelId Evergreen.V215.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) Evergreen.V215.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Slack.Id Evergreen.V215.Slack.ChannelId) Evergreen.V215.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V215.OneToOne.OneToOne String (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    , slackUsers : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Slack.Id Evergreen.V215.Slack.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    , slackServers : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Slack.Id Evergreen.V215.Slack.TeamId) (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    , slackToken : Maybe Evergreen.V215.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V215.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V215.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V215.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V215.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId, Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V215.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V215.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V215.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V215.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.LocalState.LoadingDiscordChannel (List Evergreen.V215.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V215.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId) Evergreen.V215.Sticker.StickerData
    , discordStickers : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Discord.Id Evergreen.V215.Discord.StickerId) (Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId) Evergreen.V215.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V215.OneToOne.OneToOne Evergreen.V215.RichText.DiscordCustomEmojiIdAndName (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V215.Postmark.ApiKey
    , serverSecret : Evergreen.V215.SecretId.SecretId Evergreen.V215.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V215.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V215.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V215.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V215.Route.Route
    | SelectedFilesToAttach ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V215.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V215.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V215.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V215.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V215.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V215.NonemptyDict.NonemptyDict Int Evergreen.V215.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V215.NonemptyDict.NonemptyDict Int Evergreen.V215.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V215.NonemptySet.NonemptySet (Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V215.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V215.AiChat.Msg
    | GoMsg Evergreen.V215.Pages.Go.Msg
    | UserNameEditableMsg (Evergreen.V215.Editable.Msg Evergreen.V215.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V215.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
        { fileId : Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute )
        { fileId : Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V215.Id.AnyGuildOrDmId, Evergreen.V215.Id.ThreadRoute ) (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRouteWithMessage Evergreen.V215.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V215.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V215.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) Evergreen.V215.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) Evergreen.V215.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V215.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V215.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId
        , otherUserId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V215.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRoute Evergreen.V215.MessageInput.Msg
    | MessageInputMsg Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRoute Evergreen.V215.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V215.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V215.Range.Range, Evergreen.V215.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V215.Range.Range, Evergreen.V215.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V215.VoiceChat.FromJs)
    | GotVoiceChatRecording Bytes.Bytes
    | VoiceChatMsg Evergreen.V215.VoiceChat.Msg


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V215.Id.AnyGuildOrDmId Evergreen.V215.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V215.Id.Id Evergreen.V215.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V215.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V215.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V215.Untrusted.Untrusted Evergreen.V215.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V215.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V215.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V215.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V215.PersonName.PersonName Evergreen.V215.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V215.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V215.Slack.OAuthCode Evergreen.V215.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V215.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V215.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V215.Id.Id Evergreen.V215.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V215.EmailAddress.EmailAddress (Result Evergreen.V215.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V215.EmailAddress.EmailAddress (Result Evergreen.V215.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Evergreen.V215.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V215.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMaybeMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Result Evergreen.V215.Discord.HttpError Evergreen.V215.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V215.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Result Evergreen.V215.Discord.HttpError Evergreen.V215.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Result Evergreen.V215.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Result Evergreen.V215.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Result Evergreen.V215.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Result Evergreen.V215.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji (Result Evergreen.V215.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji (Result Evergreen.V215.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji (Result Evergreen.V215.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) Evergreen.V215.Emoji.EmojiOrCustomEmoji (Result Evergreen.V215.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V215.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V215.Discord.HttpError (List ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId, Maybe Evergreen.V215.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V215.Slack.CurrentUser
            , team : Evergreen.V215.Slack.Team
            , users : List Evergreen.V215.Slack.User
            , channels : List ( Evergreen.V215.Slack.Channel, List Evergreen.V215.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Result Effect.Http.Error Evergreen.V215.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Discord.UserAuth (Result Evergreen.V215.Discord.HttpError Evergreen.V215.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Result Evergreen.V215.Discord.HttpError Evergreen.V215.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
        (Result
            Evergreen.V215.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId
                , members : List (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
                }
            , List
                ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId
                , { guild : Evergreen.V215.Discord.GatewayGuild
                  , channels : List Evergreen.V215.Discord.Channel
                  , icon : Maybe Evergreen.V215.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V215.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.AttachmentId, Evergreen.V215.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V215.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V215.Discord.Id Evergreen.V215.Discord.AttachmentId, Evergreen.V215.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V215.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V215.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V215.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V215.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) (Result Evergreen.V215.Discord.HttpError (List Evergreen.V215.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Result Evergreen.V215.Discord.HttpError (List Evergreen.V215.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V215.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V215.DmChannel.DmChannelId Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V215.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) Evergreen.V215.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V215.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V215.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
        (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V215.Discord.HttpError
            { guild : Evergreen.V215.Discord.GatewayGuild
            , channels : List Evergreen.V215.Discord.Channel
            , icon : Maybe Evergreen.V215.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId) (Result Evergreen.V215.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V215.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (List ( Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId, Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V215.Id.Id Evergreen.V215.Id.StickerId, Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (List ( Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V215.Id.Id Evergreen.V215.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V215.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V215.Discord.HttpError (List Evergreen.V215.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V215.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V215.SecretId.SecretId Evergreen.V215.SecretId.ServerSecret))
