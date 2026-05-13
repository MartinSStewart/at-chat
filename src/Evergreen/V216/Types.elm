module Evergreen.V216.Types exposing (..)

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
import Evergreen.V216.AiChat
import Evergreen.V216.ChannelName
import Evergreen.V216.Coord
import Evergreen.V216.CssPixels
import Evergreen.V216.CustomEmoji
import Evergreen.V216.Discord
import Evergreen.V216.DiscordAttachmentId
import Evergreen.V216.DiscordUserData
import Evergreen.V216.DmChannel
import Evergreen.V216.Editable
import Evergreen.V216.EmailAddress
import Evergreen.V216.Embed
import Evergreen.V216.Emoji
import Evergreen.V216.FileStatus
import Evergreen.V216.Go
import Evergreen.V216.GuildName
import Evergreen.V216.Id
import Evergreen.V216.ImageEditor
import Evergreen.V216.Local
import Evergreen.V216.LocalState
import Evergreen.V216.Log
import Evergreen.V216.LoginForm
import Evergreen.V216.MembersAndOwner
import Evergreen.V216.Message
import Evergreen.V216.MessageInput
import Evergreen.V216.MessageView
import Evergreen.V216.NonemptyDict
import Evergreen.V216.NonemptySet
import Evergreen.V216.OneToOne
import Evergreen.V216.Pages.Admin
import Evergreen.V216.Pagination
import Evergreen.V216.PersonName
import Evergreen.V216.Ports
import Evergreen.V216.Postmark
import Evergreen.V216.Range
import Evergreen.V216.RichText
import Evergreen.V216.Route
import Evergreen.V216.SecretId
import Evergreen.V216.SessionIdHash
import Evergreen.V216.Slack
import Evergreen.V216.Sticker
import Evergreen.V216.TextEditor
import Evergreen.V216.ToBackendLog
import Evergreen.V216.Touch
import Evergreen.V216.TwoFactorAuthentication
import Evergreen.V216.Ui.Anim
import Evergreen.V216.Untrusted
import Evergreen.V216.User
import Evergreen.V216.UserAgent
import Evergreen.V216.UserSession
import Evergreen.V216.VoiceChat
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V216.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V216.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.LocalState.DiscordFrontendGuild
    , user : Evergreen.V216.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V216.SessionIdHash.SessionIdHash Evergreen.V216.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V216.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId) Evergreen.V216.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V216.VoiceChat.RoomId (Evergreen.V216.NonemptySet.NonemptySet ( Evergreen.V216.Id.Id Evergreen.V216.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V216.Route.Route
    , windowSize : Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V216.Ports.NotificationPermission
    , pwaStatus : Evergreen.V216.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V216.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V216.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V216.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V216.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V216.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V216.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.ChannelName.ChannelName
    | Local_EditChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.ChannelName.ChannelName
    | Local_DeleteChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V216.GuildName.GuildName (Evergreen.V216.UserSession.ToBeFilledInByBackend (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V216.Id.GuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V216.Id.DiscordGuildOrDmId_DmData (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V216.UserSession.SetViewing
    | Local_SetName Evergreen.V216.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V216.Id.GuildOrDmId (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V216.Id.GuildOrDmId (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V216.Id.DiscordGuildOrDmId (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V216.Id.DiscordGuildOrDmId (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.Message.Message Evergreen.V216.Id.ThreadMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V216.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V216.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V216.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V216.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V216.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V216.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V216.NonemptySet.NonemptySet (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V216.VoiceChat.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        }
        Evergreen.V216.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Effect.Time.Posix Evergreen.V216.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))) Evergreen.V216.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V216.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))) Evergreen.V216.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.ChannelName.ChannelName
    | Server_EditChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.ChannelName.ChannelName
    | Server_DeleteChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V216.LocalState.JoinGuildError
            { guildId : Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId
            , guild : Evergreen.V216.LocalState.FrontendGuild
            , owner : Evergreen.V216.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.GuildOrDmId Evergreen.V216.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.GuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.GuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.GuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))) (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V216.Id.DiscordGuildOrDmId_DmData (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V216.SessionIdHash.SessionIdHash Evergreen.V216.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V216.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V216.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V216.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.ChannelName.ChannelName (Evergreen.V216.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)
        (Evergreen.V216.NonemptyDict.NonemptyDict
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Maybe (Evergreen.V216.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V216.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V216.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V216.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V216.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V216.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V216.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (Evergreen.V216.Discord.OptionalData String) (Evergreen.V216.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
        (Evergreen.V216.MembersAndOwner.MembersAndOwner
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId) Evergreen.V216.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V216.VoiceChat.ServerChange
    | Server_Go
        (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
        { otherUserId : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        }
        Evergreen.V216.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) LocalChange
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
    | GuildChannelNameHover (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V216.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V216.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V216.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V216.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels) (Maybe Evergreen.V216.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ThreadMessageId) (Evergreen.V216.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V216.Editable.Model
    , showLinkDiscordSetup : Bool
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V216.Local.Local LocalMsg Evergreen.V216.LocalState.LocalState
    , admin : Evergreen.V216.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId, Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId ) NewChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V216.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V216.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V216.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.NonemptyDict.NonemptyDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V216.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V216.TextEditor.Model
    , profilePictureEditor : Evergreen.V216.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V216.Emoji.Model
    , voiceChat : Evergreen.V216.VoiceChat.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V216.Id.Id Evergreen.V216.Id.UserId, Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) ) Evergreen.V216.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V216.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V216.Range.Range
                , direction : Evergreen.V216.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V216.NonemptyDict.NonemptyDict Int Evergreen.V216.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V216.NonemptyDict.NonemptyDict Int Evergreen.V216.Touch.Touch
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
    | AdminToFrontend Evergreen.V216.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V216.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V216.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V216.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V216.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V216.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V216.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V216.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V216.Ports.NotificationPermission
    , pwaStatus : Evergreen.V216.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V216.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V216.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V216.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V216.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V216.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V216.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V216.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId, Evergreen.V216.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V216.DmChannel.DmChannelId, Evergreen.V216.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId, Evergreen.V216.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId, Evergreen.V216.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V216.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V216.NonemptyDict.NonemptyDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V216.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V216.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V216.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V216.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V216.DmChannel.DmChannelId Evergreen.V216.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) Evergreen.V216.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Slack.Id Evergreen.V216.Slack.ChannelId) Evergreen.V216.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V216.OneToOne.OneToOne String (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    , slackUsers : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Slack.Id Evergreen.V216.Slack.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    , slackServers : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Slack.Id Evergreen.V216.Slack.TeamId) (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    , slackToken : Maybe Evergreen.V216.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V216.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V216.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V216.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V216.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId, Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V216.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V216.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V216.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V216.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.LocalState.LoadingDiscordChannel (List Evergreen.V216.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V216.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId) Evergreen.V216.Sticker.StickerData
    , discordStickers : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Discord.Id Evergreen.V216.Discord.StickerId) (Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId) Evergreen.V216.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V216.OneToOne.OneToOne Evergreen.V216.RichText.DiscordCustomEmojiIdAndName (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V216.Postmark.ApiKey
    , serverSecret : Evergreen.V216.SecretId.SecretId Evergreen.V216.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V216.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V216.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V216.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V216.Route.Route
    | SelectedFilesToAttach ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) NewChannelForm
    | PressedCancelEditChannelChanges (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) NewChannelForm
    | PressedDeleteChannel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V216.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V216.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V216.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V216.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V216.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V216.NonemptyDict.NonemptyDict Int Evergreen.V216.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V216.NonemptyDict.NonemptyDict Int Evergreen.V216.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V216.NonemptySet.NonemptySet (Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V216.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V216.AiChat.Msg
    | GoMsg Evergreen.V216.Go.Msg
    | UserNameEditableMsg (Evergreen.V216.Editable.Msg Evergreen.V216.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V216.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
        { fileId : Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute )
        { fileId : Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V216.Id.AnyGuildOrDmId, Evergreen.V216.Id.ThreadRoute ) (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRouteWithMessage Evergreen.V216.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V216.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V216.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) Evergreen.V216.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) Evergreen.V216.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V216.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V216.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId
        , otherUserId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | PressedRemoveDomainFromWhitelist Evergreen.V216.RichText.Domain
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRoute Evergreen.V216.MessageInput.Msg
    | MessageInputMsg Evergreen.V216.Id.AnyGuildOrDmId Evergreen.V216.Id.ThreadRoute Evergreen.V216.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V216.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V216.Range.Range, Evergreen.V216.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V216.Range.Range, Evergreen.V216.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V216.VoiceChat.FromJs)
    | GotVoiceChatRecording Bytes.Bytes
    | VoiceChatMsg Evergreen.V216.VoiceChat.Msg
    | PressedChannelHeaderTab Evergreen.V216.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V216.DmChannel.DmChannelId Evergreen.V216.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V216.Id.DiscordGuildOrDmId Evergreen.V216.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V216.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V216.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V216.Untrusted.Untrusted Evergreen.V216.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V216.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V216.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V216.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.SecretId.SecretId Evergreen.V216.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V216.PersonName.PersonName Evergreen.V216.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V216.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V216.Slack.OAuthCode Evergreen.V216.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V216.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V216.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V216.EmailAddress.EmailAddress (Result Evergreen.V216.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V216.EmailAddress.EmailAddress (Result Evergreen.V216.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Evergreen.V216.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V216.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMaybeMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Result Evergreen.V216.Discord.HttpError Evergreen.V216.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V216.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Result Evergreen.V216.Discord.HttpError Evergreen.V216.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Result Evergreen.V216.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Result Evergreen.V216.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Result Evergreen.V216.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Result Evergreen.V216.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji (Result Evergreen.V216.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji (Result Evergreen.V216.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji (Result Evergreen.V216.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) Evergreen.V216.Emoji.EmojiOrCustomEmoji (Result Evergreen.V216.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V216.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V216.Discord.HttpError (List ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId, Maybe Evergreen.V216.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V216.Slack.CurrentUser
            , team : Evergreen.V216.Slack.Team
            , users : List Evergreen.V216.Slack.User
            , channels : List ( Evergreen.V216.Slack.Channel, List Evergreen.V216.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Result Effect.Http.Error Evergreen.V216.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Discord.UserAuth (Result Evergreen.V216.Discord.HttpError Evergreen.V216.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Result Evergreen.V216.Discord.HttpError Evergreen.V216.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
        (Result
            Evergreen.V216.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId
                , members : List (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
                }
            , List
                ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId
                , { guild : Evergreen.V216.Discord.GatewayGuild
                  , channels : List Evergreen.V216.Discord.Channel
                  , icon : Maybe Evergreen.V216.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V216.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.AttachmentId, Evergreen.V216.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V216.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V216.Discord.Id Evergreen.V216.Discord.AttachmentId, Evergreen.V216.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V216.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V216.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V216.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V216.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) (Result Evergreen.V216.Discord.HttpError (List Evergreen.V216.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Result Evergreen.V216.Discord.HttpError (List Evergreen.V216.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V216.Id.Id Evergreen.V216.Id.GuildId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V216.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V216.DmChannel.DmChannelId Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V216.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Evergreen.V216.Discord.Id Evergreen.V216.Discord.ChannelId) Evergreen.V216.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V216.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V216.Discord.Id Evergreen.V216.Discord.PrivateChannelId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V216.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
        (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V216.Discord.HttpError
            { guild : Evergreen.V216.Discord.GatewayGuild
            , channels : List Evergreen.V216.Discord.Channel
            , icon : Maybe Evergreen.V216.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V216.Discord.Id Evergreen.V216.Discord.GuildId) (Result Evergreen.V216.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V216.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (List ( Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId, Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V216.Id.Id Evergreen.V216.Id.StickerId, Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (List ( Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V216.Id.Id Evergreen.V216.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V216.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V216.Discord.HttpError (List Evergreen.V216.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V216.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V216.SecretId.SecretId Evergreen.V216.SecretId.ServerSecret))
