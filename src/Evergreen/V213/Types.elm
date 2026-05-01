module Evergreen.V213.Types exposing (..)

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
import Evergreen.V213.AiChat
import Evergreen.V213.ChannelName
import Evergreen.V213.Coord
import Evergreen.V213.CssPixels
import Evergreen.V213.CustomEmoji
import Evergreen.V213.Discord
import Evergreen.V213.DiscordAttachmentId
import Evergreen.V213.DiscordUserData
import Evergreen.V213.DmChannel
import Evergreen.V213.Editable
import Evergreen.V213.EmailAddress
import Evergreen.V213.Embed
import Evergreen.V213.Emoji
import Evergreen.V213.FileStatus
import Evergreen.V213.GuildName
import Evergreen.V213.Id
import Evergreen.V213.ImageEditor
import Evergreen.V213.Local
import Evergreen.V213.LocalState
import Evergreen.V213.Log
import Evergreen.V213.LoginForm
import Evergreen.V213.MembersAndOwner
import Evergreen.V213.Message
import Evergreen.V213.MessageInput
import Evergreen.V213.MessageView
import Evergreen.V213.NonemptyDict
import Evergreen.V213.NonemptySet
import Evergreen.V213.OneToOne
import Evergreen.V213.Pages.Admin
import Evergreen.V213.Pagination
import Evergreen.V213.PersonName
import Evergreen.V213.Ports
import Evergreen.V213.Postmark
import Evergreen.V213.Range
import Evergreen.V213.RichText
import Evergreen.V213.Route
import Evergreen.V213.SecretId
import Evergreen.V213.SessionIdHash
import Evergreen.V213.Slack
import Evergreen.V213.Sticker
import Evergreen.V213.TextEditor
import Evergreen.V213.ToBackendLog
import Evergreen.V213.Touch
import Evergreen.V213.TwoFactorAuthentication
import Evergreen.V213.Ui.Anim
import Evergreen.V213.Untrusted
import Evergreen.V213.User
import Evergreen.V213.UserAgent
import Evergreen.V213.UserSession
import Evergreen.V213.VoiceChat
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V213.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V213.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) Evergreen.V213.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.LocalState.DiscordFrontendGuild
    , user : Evergreen.V213.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V213.SessionIdHash.SessionIdHash Evergreen.V213.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V213.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId) Evergreen.V213.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V213.VoiceChat.RoomId (Evergreen.V213.NonemptySet.NonemptySet ( Evergreen.V213.Id.Id Evergreen.V213.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V213.Route.Route
    , windowSize : Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V213.Ports.NotificationPermission
    , pwaStatus : Evergreen.V213.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V213.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V213.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V213.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V213.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V213.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V213.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.UserSession.ToBeFilledInByBackend (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V213.GuildName.GuildName (Evergreen.V213.UserSession.ToBeFilledInByBackend (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V213.Id.GuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V213.Id.DiscordGuildOrDmId_DmData (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V213.UserSession.SetViewing
    | Local_SetName Evergreen.V213.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V213.Id.GuildOrDmId (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V213.Id.GuildOrDmId (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V213.Id.DiscordGuildOrDmId (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V213.Id.DiscordGuildOrDmId (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.Message.Message Evergreen.V213.Id.ThreadMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V213.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V213.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V213.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V213.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V213.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V213.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V213.NonemptySet.NonemptySet (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V213.VoiceChat.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Effect.Time.Posix Evergreen.V213.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))) Evergreen.V213.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V213.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))) Evergreen.V213.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V213.LocalState.JoinGuildError
            { guildId : Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId
            , guild : Evergreen.V213.LocalState.FrontendGuild
            , owner : Evergreen.V213.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.GuildOrDmId Evergreen.V213.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.GuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.GuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.GuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))) (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V213.Id.DiscordGuildOrDmId_DmData (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V213.SessionIdHash.SessionIdHash Evergreen.V213.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V213.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V213.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V213.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.ChannelName.ChannelName (Evergreen.V213.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId)
        (Evergreen.V213.NonemptyDict.NonemptyDict
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) Evergreen.V213.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Maybe (Evergreen.V213.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V213.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V213.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V213.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V213.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V213.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V213.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (Evergreen.V213.Discord.OptionalData String) (Evergreen.V213.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId)
        (Evergreen.V213.MembersAndOwner.MembersAndOwner
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId) Evergreen.V213.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V213.VoiceChat.ServerChange


type LocalMsg
    = LocalChange (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V213.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V213.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V213.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V213.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels) (Maybe Evergreen.V213.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId) (Evergreen.V213.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V213.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V213.Local.Local LocalMsg Evergreen.V213.LocalState.LocalState
    , admin : Evergreen.V213.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId, Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V213.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V213.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V213.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.NonemptyDict.NonemptyDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V213.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V213.TextEditor.Model
    , profilePictureEditor : Evergreen.V213.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V213.Emoji.Model
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V213.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V213.Range.Range
                , direction : Evergreen.V213.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V213.NonemptyDict.NonemptyDict Int Evergreen.V213.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V213.NonemptyDict.NonemptyDict Int Evergreen.V213.Touch.Touch
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
    | AdminToFrontend Evergreen.V213.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V213.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V213.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V213.AiChat.ToFrontend
    | YouConnected
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V213.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V213.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V213.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V213.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V213.Ports.NotificationPermission
    , pwaStatus : Evergreen.V213.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V213.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V213.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V213.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V213.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V213.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V213.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V213.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId, Evergreen.V213.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V213.DmChannel.DmChannelId, Evergreen.V213.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId, Evergreen.V213.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId, Evergreen.V213.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V213.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V213.NonemptyDict.NonemptyDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V213.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V213.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V213.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V213.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V213.DmChannel.DmChannelId Evergreen.V213.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) Evergreen.V213.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Slack.Id Evergreen.V213.Slack.ChannelId) Evergreen.V213.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V213.OneToOne.OneToOne String (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId)
    , slackUsers : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Slack.Id Evergreen.V213.Slack.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
    , slackServers : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Slack.Id Evergreen.V213.Slack.TeamId) (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId)
    , slackToken : Maybe Evergreen.V213.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V213.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V213.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V213.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V213.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId, Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V213.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V213.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V213.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V213.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.LocalState.LoadingDiscordChannel (List Evergreen.V213.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V213.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId) Evergreen.V213.Sticker.StickerData
    , discordStickers : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Discord.Id Evergreen.V213.Discord.StickerId) (Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId) Evergreen.V213.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V213.OneToOne.OneToOne Evergreen.V213.RichText.DiscordCustomEmojiIdAndName (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V213.Postmark.ApiKey
    , serverSecret : Evergreen.V213.SecretId.SecretId Evergreen.V213.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V213.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V213.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V213.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V213.Route.Route
    | SelectedFilesToAttach ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V213.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V213.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V213.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V213.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V213.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V213.NonemptyDict.NonemptyDict Int Evergreen.V213.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V213.NonemptyDict.NonemptyDict Int Evergreen.V213.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V213.NonemptySet.NonemptySet (Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V213.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V213.AiChat.Msg
    | UserNameEditableMsg (Evergreen.V213.Editable.Msg Evergreen.V213.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V213.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
        { fileId : Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute )
        { fileId : Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V213.Id.AnyGuildOrDmId, Evergreen.V213.Id.ThreadRoute ) (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRouteWithMessage Evergreen.V213.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V213.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V213.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) Evergreen.V213.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) Evergreen.V213.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V213.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V213.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId
        , otherUserId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V213.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRoute Evergreen.V213.MessageInput.Msg
    | MessageInputMsg Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRoute Evergreen.V213.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V213.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V213.Range.Range, Evergreen.V213.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V213.Range.Range, Evergreen.V213.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | PressedVoiceChatButton Evergreen.V213.VoiceChat.RoomId
    | GotVoiceChatSignalFromJs Evergreen.V213.VoiceChat.ConnectionId Evergreen.V213.VoiceChat.Signal


type InitialLoadRequest
    = InitialLoadRequested_Channel Evergreen.V213.Id.AnyGuildOrDmId Evergreen.V213.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V213.Id.Id Evergreen.V213.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V213.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V213.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V213.Untrusted.Untrusted Evergreen.V213.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V213.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V213.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V213.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V213.PersonName.PersonName Evergreen.V213.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V213.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V213.Slack.OAuthCode Evergreen.V213.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V213.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V213.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V213.Id.Id Evergreen.V213.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V213.EmailAddress.EmailAddress (Result Evergreen.V213.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V213.EmailAddress.EmailAddress (Result Evergreen.V213.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Evergreen.V213.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V213.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMaybeMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Result Evergreen.V213.Discord.HttpError Evergreen.V213.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V213.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Result Evergreen.V213.Discord.HttpError Evergreen.V213.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Result Evergreen.V213.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Result Evergreen.V213.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Result Evergreen.V213.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Result Evergreen.V213.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji (Result Evergreen.V213.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji (Result Evergreen.V213.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji (Result Evergreen.V213.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) Evergreen.V213.Emoji.EmojiOrCustomEmoji (Result Evergreen.V213.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V213.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V213.Discord.HttpError (List ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId, Maybe Evergreen.V213.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V213.Slack.CurrentUser
            , team : Evergreen.V213.Slack.Team
            , users : List Evergreen.V213.Slack.User
            , channels : List ( Evergreen.V213.Slack.Channel, List Evergreen.V213.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Result Effect.Http.Error Evergreen.V213.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) Evergreen.V213.Discord.UserAuth (Result Evergreen.V213.Discord.HttpError Evergreen.V213.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Result Evergreen.V213.Discord.HttpError Evergreen.V213.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
        (Result
            Evergreen.V213.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId
                , members : List (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
                }
            , List
                ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId
                , { guild : Evergreen.V213.Discord.GatewayGuild
                  , channels : List Evergreen.V213.Discord.Channel
                  , icon : Maybe Evergreen.V213.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V213.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.AttachmentId, Evergreen.V213.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V213.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V213.Discord.Id Evergreen.V213.Discord.AttachmentId, Evergreen.V213.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V213.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V213.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V213.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V213.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) (Result Evergreen.V213.Discord.HttpError (List Evergreen.V213.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Result Evergreen.V213.Discord.HttpError (List Evergreen.V213.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V213.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V213.DmChannel.DmChannelId Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V213.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) Evergreen.V213.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V213.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V213.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
        (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V213.Discord.HttpError
            { guild : Evergreen.V213.Discord.GatewayGuild
            , channels : List Evergreen.V213.Discord.Channel
            , icon : Maybe Evergreen.V213.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId) (Result Evergreen.V213.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V213.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (List ( Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId, Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V213.Id.Id Evergreen.V213.Id.StickerId, Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (List ( Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V213.Id.Id Evergreen.V213.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V213.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V213.Discord.HttpError (List Evergreen.V213.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V213.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V213.SecretId.SecretId Evergreen.V213.SecretId.ServerSecret))
