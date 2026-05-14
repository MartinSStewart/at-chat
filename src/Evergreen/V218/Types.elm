module Evergreen.V218.Types exposing (..)

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
import Evergreen.V218.AiChat
import Evergreen.V218.ChannelDescription
import Evergreen.V218.ChannelName
import Evergreen.V218.Coord
import Evergreen.V218.CssPixels
import Evergreen.V218.CustomEmoji
import Evergreen.V218.Discord
import Evergreen.V218.DiscordAttachmentId
import Evergreen.V218.DiscordUserData
import Evergreen.V218.DmChannel
import Evergreen.V218.Editable
import Evergreen.V218.EmailAddress
import Evergreen.V218.Embed
import Evergreen.V218.Emoji
import Evergreen.V218.FileStatus
import Evergreen.V218.Go
import Evergreen.V218.GuildName
import Evergreen.V218.Id
import Evergreen.V218.ImageEditor
import Evergreen.V218.Local
import Evergreen.V218.LocalState
import Evergreen.V218.Log
import Evergreen.V218.LoginForm
import Evergreen.V218.MembersAndOwner
import Evergreen.V218.Message
import Evergreen.V218.MessageInput
import Evergreen.V218.MessageView
import Evergreen.V218.NonemptyDict
import Evergreen.V218.NonemptySet
import Evergreen.V218.OneToOne
import Evergreen.V218.Pages.Admin
import Evergreen.V218.Pagination
import Evergreen.V218.PersonName
import Evergreen.V218.Ports
import Evergreen.V218.Postmark
import Evergreen.V218.Range
import Evergreen.V218.RichText
import Evergreen.V218.Route
import Evergreen.V218.SecretId
import Evergreen.V218.SessionIdHash
import Evergreen.V218.Slack
import Evergreen.V218.Sticker
import Evergreen.V218.TextEditor
import Evergreen.V218.ToBackendLog
import Evergreen.V218.Touch
import Evergreen.V218.TwoFactorAuthentication
import Evergreen.V218.Ui.Anim
import Evergreen.V218.Untrusted
import Evergreen.V218.User
import Evergreen.V218.UserAgent
import Evergreen.V218.UserSession
import Evergreen.V218.VoiceChat
import List.Nonempty
import Quantity
import SeqDict
import String.Nonempty
import Url


type AdminStatusLoginData
    = IsAdminLoginData Evergreen.V218.Pages.Admin.InitAdminData
    | IsAdminButNoData
    | IsNotAdminLoginData


type alias LoginData =
    { session : Evergreen.V218.UserSession.UserSession
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Effect.Time.Posix
    , guilds : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.LocalState.FrontendGuild
    , dmChannels : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.DmChannel.FrontendDmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.DmChannel.DiscordFrontendDmChannel
    , discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.LocalState.DiscordFrontendGuild
    , user : Evergreen.V218.User.FrontendCurrentUser
    , otherUsers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.User.FrontendUser
    , otherDiscordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.User.DiscordFrontendUser
    , linkedDiscordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.User.DiscordFrontendCurrentUser
    , otherSessions : SeqDict.SeqDict Evergreen.V218.SessionIdHash.SessionIdHash Evergreen.V218.UserSession.FrontendUserSession
    , publicVapidKey : String
    , textEditor : Evergreen.V218.TextEditor.LocalState
    , stickers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData
    , customEmojis : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId) Evergreen.V218.CustomEmoji.CustomEmojiData
    , voiceChatPeers : SeqDict.SeqDict Evergreen.V218.VoiceChat.RoomId (Evergreen.V218.NonemptySet.NonemptySet ( Evergreen.V218.Id.Id Evergreen.V218.Id.UserId, Effect.Lamdera.ClientId ))
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Maybe Effect.Lamdera.ClientId
    , route : Evergreen.V218.Route.Route
    , windowSize : Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels
    , time : Maybe Effect.Time.Posix
    , loginStatus : LoadStatus
    , notificationPermission : Evergreen.V218.Ports.NotificationPermission
    , pwaStatus : Evergreen.V218.Ports.PwaStatus
    , timezone : Effect.Time.Zone
    , scrollbarWidth : Int
    , userAgent : Maybe Evergreen.V218.UserAgent.UserAgent
    }


type LocalChange
    = Local_Invalid
    | Local_Admin Evergreen.V218.Pages.Admin.AdminChange
    | Local_SendMessage Effect.Time.Posix Evergreen.V218.Id.GuildOrDmId String.Nonempty.NonemptyString Evergreen.V218.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData)
    | Local_Discord_SendMessage Effect.Time.Posix Evergreen.V218.Id.DiscordGuildOrDmId String.Nonempty.NonemptyString Evergreen.V218.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData)
    | Local_NewChannel Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.ChannelName.ChannelName Evergreen.V218.ChannelDescription.ChannelDescription
    | Local_EditChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.ChannelName.ChannelName Evergreen.V218.ChannelDescription.ChannelDescription
    | Local_DeleteChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId)
    | Local_NewInviteLink Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId))
    | Local_NewGuild Effect.Time.Posix Evergreen.V218.GuildName.GuildName (Evergreen.V218.UserSession.ToBeFilledInByBackend (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId))
    | Local_MemberTyping Effect.Time.Posix ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    | Local_AddReactionEmoji Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Local_RemoveReactionEmoji Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Local_SendEditMessage Effect.Time.Posix Evergreen.V218.Id.GuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData)
    | Local_Discord_SendEditGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage String.Nonempty.NonemptyString
    | Local_Discord_SendEditDmMessage Effect.Time.Posix Evergreen.V218.Id.DiscordGuildOrDmId_DmData (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) String.Nonempty.NonemptyString
    | Local_MemberEditTyping Effect.Time.Posix Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | Local_SetLastViewed Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | Local_DeleteMessage Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | Local_CurrentlyViewing Evergreen.V218.UserSession.SetViewing
    | Local_SetName Evergreen.V218.PersonName.PersonName
    | Local_LoadChannelMessages Evergreen.V218.Id.GuildOrDmId (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | Local_LoadThreadMessages Evergreen.V218.Id.GuildOrDmId (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))))
    | Local_Discord_LoadChannelMessages Evergreen.V218.Id.DiscordGuildOrDmId (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))))
    | Local_Discord_LoadThreadMessages Evergreen.V218.Id.DiscordGuildOrDmId (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.UserSession.ToBeFilledInByBackend (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.Message.Message Evergreen.V218.Id.ThreadMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))))
    | Local_SetGuildNotificationLevel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.User.NotificationLevel
    | Local_SetDiscordGuildNotificationLevel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.User.NotificationLevel
    | Local_SetNotificationMode Evergreen.V218.UserSession.NotificationMode
    | Local_RegisterPushSubscription Evergreen.V218.UserSession.SubscribeData
    | Local_TextEditor Evergreen.V218.TextEditor.LocalChange
    | Local_UnlinkDiscordUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | Local_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | Local_LinkDiscordAcknowledgementIsChecked Bool
    | Local_SetDomainWhitelist Bool Evergreen.V218.RichText.Domain
    | Local_SetEmojiCategory Evergreen.V218.Emoji.Category
    | Local_SetEmojiSkinTone (Maybe Evergreen.V218.Emoji.SkinTone)
    | Local_AddCustomEmojisToUser (Evergreen.V218.NonemptySet.NonemptySet (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId))
    | Local_VoiceChatChange Evergreen.V218.VoiceChat.LocalChange
    | Local_Go
        { otherUserId : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        }
        Evergreen.V218.Go.LocalChange


type ServerChange
    = Server_SendMessage (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Effect.Time.Posix Evergreen.V218.Id.GuildOrDmId (List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))) Evergreen.V218.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData)
    | Server_Discord_SendMessage Effect.Time.Posix Evergreen.V218.Id.DiscordGuildOrDmId (List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))) Evergreen.V218.Id.ThreadRouteWithMaybeMessage (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData) (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData)
    | Server_NewChannel Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.ChannelName.ChannelName Evergreen.V218.ChannelDescription.ChannelDescription
    | Server_EditChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.ChannelName.ChannelName Evergreen.V218.ChannelDescription.ChannelDescription
    | Server_DeleteChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId)
    | Server_NewInviteLink Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)
    | Server_MemberJoined Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.User.FrontendUser
    | Server_YouJoinedGuildByInvite
        (Result
            Evergreen.V218.LocalState.JoinGuildError
            { guildId : Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId
            , guild : Evergreen.V218.LocalState.FrontendGuild
            , owner : Evergreen.V218.User.FrontendUser
            , members : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.User.FrontendUser
            }
        )
    | Server_MemberTyping Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.GuildOrDmId Evergreen.V218.Id.ThreadRoute
    | Server_DiscordGuildMemberTyping Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRoute
    | Server_DiscordDmMemberTyping Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
    | Server_AddReactionEmoji (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.GuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_RemoveReactionEmoji (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.GuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionGuildEmoji (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_DiscordAddReactionDmEmoji (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionGuildEmoji (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_DiscordRemoveReactionDmEmoji (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | Server_SendEditMessage Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.GuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))) (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData)
    | Server_DiscordSendEditGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)))
    | Server_DiscordSendEditDmMessage Effect.Time.Posix Evergreen.V218.Id.DiscordGuildOrDmId_DmData (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)))
    | Server_MemberEditTyping Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | Server_DeleteMessage Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteGuildMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage
    | Server_DiscordDeleteDmMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    | Server_SetName (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.PersonName.PersonName
    | Server_SetUserIcon (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.FileStatus.FileHash
    | Server_PushNotificationsReset String
    | Server_SetGuildNotificationLevel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.User.NotificationLevel
    | Server_SetDiscordGuildNotificationLevel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.User.NotificationLevel
    | Server_PushNotificationFailed Effect.Http.Error
    | Server_NewSession Evergreen.V218.SessionIdHash.SessionIdHash Evergreen.V218.UserSession.FrontendUserSession
    | Server_LoggedOut Evergreen.V218.SessionIdHash.SessionIdHash
    | Server_CurrentlyViewing Evergreen.V218.SessionIdHash.SessionIdHash (Maybe ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ))
    | Server_TextEditor Evergreen.V218.TextEditor.ServerChange
    | Server_LinkDiscordUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.User.DiscordFrontendCurrentUser
    | Server_UnlinkDiscordUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | Server_DiscordChannelCreated (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.ChannelName.ChannelName (Evergreen.V218.Discord.OptionalData (Maybe String))
    | Server_DiscordDmChannelCreated
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)
        (Evergreen.V218.NonemptyDict.NonemptyDict
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { messagesSent : Int
            }
        )
    | Server_DiscordNeedsAuthAgain (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | Server_DiscordUserLoadingDataIsDone
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
        (Result
            Effect.Time.Posix
            { discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.LocalState.DiscordFrontendGuild
            , discordDms : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.DmChannel.DiscordFrontendDmChannel
            , discordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.User.DiscordFrontendUser
            }
        )
    | Server_StartReloadingDiscordUser Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | Server_LoadingDiscordChannelChanged (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Maybe (Evergreen.V218.LocalState.LoadingDiscordChannel Int))
    | Server_LoadAdminData Evergreen.V218.Pages.Admin.InitAdminData
    | Server_NewLog Effect.Time.Posix Evergreen.V218.Log.Log
    | Server_GotGuildMessageEmbed (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V218.Embed.EmbedData )
    | Server_GotDmMessageEmbed (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V218.Embed.EmbedData )
    | Server_GotDiscordGuildMessageEmbed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result () Evergreen.V218.Embed.EmbedData )
    | Server_GotDiscordDmMessageEmbed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) ( Url.Url, Result () Evergreen.V218.Embed.EmbedData )
    | Server_DiscordGuildJoinedOrCreated (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.LocalState.DiscordFrontendGuild
    | Server_DiscordUpdateChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (Evergreen.V218.Discord.OptionalData String) (Evergreen.V218.Discord.OptionalData (Maybe String))
    | Server_UpdateDiscordMembers
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
        (Evergreen.V218.MembersAndOwner.MembersAndOwner
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { joinedAt : Maybe Effect.Time.Posix
            }
        )
    | Server_DiscordGuildMemberJoined Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.PersonName.PersonName
    | Server_LinkedDiscordUserStickersLoaded (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData)
    | Server_LinkedDiscordUserCustomEmojisLoaded (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId) Evergreen.V218.CustomEmoji.CustomEmojiData)
    | Server_VoiceChatChange Evergreen.V218.VoiceChat.ServerChange
    | Server_Go
        (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
        { otherUserId : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        }
        Evergreen.V218.Go.LocalChange


type LocalMsg
    = LocalChange (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) LocalChange
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


type alias NewGuildForm =
    { name : String
    , pressedSubmit : Bool
    }


type GuildChannelNameHover
    = NoChannelNameHover
    | GuildChannelNameHover (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRoute
    | DiscordGuildChannelNameHover (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRoute


type alias EditMessage =
    { messageIndex : Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId
    , text : String
    , attachedFiles : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileStatus
    }


type MessageHoverMobileMode
    = MessageMenuClosing (Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels) (Maybe EditMessage)
    | MessageMenuOpening
        { offset : Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels
        , targetOffset : Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels
        }
    | MessageMenuDragging
        { offset : Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels
        , previousOffset : Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels
        , time : Effect.Time.Posix
        }
    | MessageMenuFixed (Quantity.Quantity Float Evergreen.V218.CssPixels.CssPixels)


type alias MessageMenuExtraOptions =
    { position : Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels
    , guildOrDmId : Evergreen.V218.Id.AnyGuildOrDmId
    , isThreadStarter : Bool
    , threadRoute : Evergreen.V218.Id.ThreadRouteWithMessage
    , mobileMode : MessageHoverMobileMode
    }


type MessageHover
    = NoMessageHover
    | MessageHover Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | MessageMenu MessageMenuExtraOptions


type EmojiSelector
    = EmojiSelectorHidden
    | EmojiSelectorForReaction Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | EmojiSelectorForMessage (Maybe Evergreen.V218.Range.Range)
    | EmojiSelectorForEditMessage (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels) (Maybe Evergreen.V218.Range.Range)


type alias RevealedSpoilers =
    { guildOrDmId : ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    , messages : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.NonemptySet.NonemptySet Int)
    , threadMessages : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId) (Evergreen.V218.NonemptySet.NonemptySet Int))
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
    { name : Evergreen.V218.Editable.Model
    , showLinkDiscordSetup : Bool
    , domainWhitelistInput : String
    }


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


type alias LoggedIn2 =
    { localState : Evergreen.V218.Local.Local LocalMsg Evergreen.V218.LocalState.LocalState
    , admin : Evergreen.V218.Pages.Admin.Model
    , drafts : SeqDict.SeqDict ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) String.Nonempty.NonemptyString
    , newChannelForm : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) NewChannelForm
    , editChannelForm : SeqDict.SeqDict ( Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId, Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId ) EditChannelForm
    , newGuildForm : Maybe NewGuildForm
    , channelNameHover : GuildChannelNameHover
    , typingDebouncer : Bool
    , textInputFocus : Maybe Evergreen.V218.MessageInput.TextInputFocus
    , previousTextInputFocus : Maybe Evergreen.V218.MessageInput.TextInputFocus
    , messageHover : MessageHover
    , showEmojiSelector : EmojiSelector
    , editMessage : SeqDict.SeqDict ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) EditMessage
    , replyTo : SeqDict.SeqDict ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    , revealedSpoilers : Maybe RevealedSpoilers
    , sidebarMode : ChannelSidebarMode
    , userOptions : Maybe UserOptionsModel
    , twoFactor : Evergreen.V218.TwoFactorAuthentication.TwoFactorState
    , filesToUpload : SeqDict.SeqDict ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.NonemptyDict.NonemptyDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileStatus)
    , showFileToUploadInfo : Maybe Evergreen.V218.FileStatus.FileDataWithImage
    , isReloading : Bool
    , channelScrollPosition : ScrollPosition
    , textEditor : Evergreen.V218.TextEditor.Model
    , profilePictureEditor : Evergreen.V218.ImageEditor.Model
    , externalLinkWarning : Maybe Url.Url
    , emojiSelector : Evergreen.V218.Emoji.Model
    , voiceChat : Evergreen.V218.VoiceChat.Model
    , currentDmGoMatch : SeqDict.SeqDict ( Evergreen.V218.Id.Id Evergreen.V218.Id.UserId, Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) ) Evergreen.V218.Go.Model
    , fileDragOverCount : Int
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn
        { loginForm : Maybe Evergreen.V218.LoginForm.LoginForm
        , useInviteAfterLoggedIn : Maybe (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)
        , textInputFocus :
            Maybe
                { htmlId : Effect.Browser.Dom.HtmlId
                , selection : Evergreen.V218.Range.Range
                , direction : Evergreen.V218.Range.SelectionDirection
                }
        }


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V218.NonemptyDict.NonemptyDict Int Evergreen.V218.Touch.Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V218.NonemptyDict.NonemptyDict Int Evergreen.V218.Touch.Touch
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
    | AdminToFrontend Evergreen.V218.Pages.Admin.ToFrontend
    | LocalChangeResponse Evergreen.V218.Local.ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | TwoFactorAuthenticationToFrontend Evergreen.V218.TwoFactorAuthentication.ToFrontend
    | AiChatToFrontend Evergreen.V218.AiChat.ToFrontend
    | YouConnected Effect.Lamdera.ClientId
    | ReloadDataResponse (Result () LoginData)
    | LinkDiscordResponse (Result Evergreen.V218.Discord.HttpError ())
    | ProfilePictureEditorToFrontend Evergreen.V218.ImageEditor.ToFrontend


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , clientId : Effect.Lamdera.ClientId
    , route : Evergreen.V218.Route.Route
    , time : Effect.Time.Posix
    , timezone : Effect.Time.Zone
    , windowSize : Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels
    , virtualKeyboardOpen : Bool
    , loginStatus : LoginStatus
    , elmUiState : Evergreen.V218.Ui.Anim.State
    , lastCopied :
        Maybe
            { copiedAt : Effect.Time.Posix
            , copiedText : String
            }
    , notificationPermission : Evergreen.V218.Ports.NotificationPermission
    , pwaStatus : Evergreen.V218.Ports.PwaStatus
    , drag : Drag
    , dragPrevious : Drag
    , aiChatModel : Evergreen.V218.AiChat.FrontendModel
    , scrollbarWidth : Int
    , userAgent : Evergreen.V218.UserAgent.UserAgent
    , pageHasFocus : Bool
    , versionNumber : Maybe Int
    , emojiData : Maybe Evergreen.V218.Emoji.CachedEmojiData
    , toFrontendLogs : Maybe (Array.Array ToFrontend)
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias WaitingForLoginTokenData =
    { creationTime : Effect.Time.Posix
    , userId : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , loginAttempts : Int
    , loginCode : Int
    }


type LoginTokenData
    = WaitingForLoginToken WaitingForLoginTokenData
    | WaitingForTwoFactorToken
        { creationTime : Effect.Time.Posix
        , userId : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
        , loginAttempts : Int
        }
    | WaitingForLoginTokenForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V218.EmailAddress.EmailAddress
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForUserDataForSignup
        { creationTime : Effect.Time.Posix
        , emailAddress : Evergreen.V218.EmailAddress.EmailAddress
        }


type alias BackendFileData =
    { fileSize : Int
    , imageSize : Maybe (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels)
    }


type alias DiscordAttachmentData =
    { fileHash : Evergreen.V218.FileStatus.FileHash
    , imageMetadata : Maybe Evergreen.V218.FileStatus.ImageMetadata
    }


type alias ExportStateProgress =
    { baseModel : Bytes.Bytes
    , remainingGuilds : List ( Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId, Evergreen.V218.LocalState.BackendGuild )
    , encodedGuilds : List Bytes.Bytes
    , remainingDmChannels : List ( Evergreen.V218.DmChannel.DmChannelId, Evergreen.V218.DmChannel.DmChannel )
    , encodedDmChannels : List Bytes.Bytes
    , remainingDiscordGuilds : List ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId, Evergreen.V218.LocalState.DiscordBackendGuild )
    , encodedDiscordGuilds : List Bytes.Bytes
    , remainingDiscordDmChannels : List ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId, Evergreen.V218.DmChannel.DiscordDmChannel )
    , encodedDiscordDmChannels : List Bytes.Bytes
    }


type alias ExportState =
    { progress : ExportStateProgress
    , exportSubset : Evergreen.V218.Pages.Admin.ExportSubset
    , clientId : Effect.Lamdera.ClientId
    }


type alias BackendModel =
    { users : Evergreen.V218.NonemptyDict.NonemptyDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.User.BackendUser
    , sessions : SeqDict.SeqDict Effect.Lamdera.SessionId Evergreen.V218.UserSession.UserSession
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (Evergreen.V218.NonemptyDict.NonemptyDict Effect.Lamdera.ClientId Evergreen.V218.LocalState.ConnectionData)
    , secretCounter : Int
    , pendingLogins : SeqDict.SeqDict Effect.Lamdera.SessionId LoginTokenData
    , logs :
        Array.Array
            { time : Effect.Time.Posix
            , log : Evergreen.V218.Log.Log
            , isHidden : Bool
            }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Effect.Time.Posix
    , twoFactorAuthentication : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.TwoFactorAuthentication.TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.TwoFactorAuthentication.TwoFactorAuthenticationSetup
    , guilds : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.LocalState.BackendGuild
    , isInitialized : Bool
    , discordGuilds : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.LocalState.DiscordBackendGuild
    , dmChannels : SeqDict.SeqDict Evergreen.V218.DmChannel.DmChannelId Evergreen.V218.DmChannel.DmChannel
    , discordDmChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) Evergreen.V218.DmChannel.DiscordDmChannel
    , slackDms : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Slack.Id Evergreen.V218.Slack.ChannelId) Evergreen.V218.DmChannel.DmChannelId
    , slackWorkspaces : Evergreen.V218.OneToOne.OneToOne String (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    , slackUsers : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Slack.Id Evergreen.V218.Slack.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    , slackServers : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Slack.Id Evergreen.V218.Slack.TeamId) (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    , slackToken : Maybe Evergreen.V218.Slack.AuthToken
    , files : SeqDict.SeqDict Evergreen.V218.FileStatus.FileHash BackendFileData
    , privateVapidKey : Evergreen.V218.LocalState.PrivateVapidKey
    , publicVapidKey : String
    , slackClientSecret : Maybe Evergreen.V218.Slack.ClientSecret
    , openRouterKey : Maybe String
    , textEditor : Evergreen.V218.TextEditor.LocalState
    , discordUsers : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.DiscordUserData.DiscordUserData
    , pendingDiscordCreateMessages : SeqDict.SeqDict ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId, Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId ) ( Effect.Lamdera.ClientId, Evergreen.V218.Local.ChangeId )
    , pendingDiscordCreateDmMessages : SeqDict.SeqDict Evergreen.V218.Id.DiscordGuildOrDmId_DmData ( Effect.Lamdera.ClientId, Evergreen.V218.Local.ChangeId )
    , discordAttachments : SeqDict.SeqDict Evergreen.V218.DiscordAttachmentId.DiscordAttachmentId DiscordAttachmentData
    , loadingDiscordChannels : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.LocalState.LoadingDiscordChannel (List Evergreen.V218.Discord.Message))
    , signupsEnabled : Bool
    , exportState : Maybe ExportState
    , scheduledExportState : Maybe ExportStateProgress
    , lastScheduledExportTime : Maybe Effect.Time.Posix
    , sendMessageRateLimits : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Array.Array Effect.Time.Posix)
    , toBackendLogs : Array.Array Evergreen.V218.ToBackendLog.ToBackendLogData
    , stickers : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId) Evergreen.V218.Sticker.StickerData
    , discordStickers : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Discord.Id Evergreen.V218.Discord.StickerId) (Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId)
    , customEmojis : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId) Evergreen.V218.CustomEmoji.CustomEmojiData
    , discordCustomEmojis : Evergreen.V218.OneToOne.OneToOne Evergreen.V218.RichText.DiscordCustomEmojiIdAndName (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId)
    , postmarkApiKey : Evergreen.V218.Postmark.ApiKey
    , serverSecret : Evergreen.V218.SecretId.SecretId Evergreen.V218.SecretId.ServerSecret
    , serverSecretRegeneratedAt : Maybe Effect.Time.Posix
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Effect.Time.Posix
    | GotWindowSize Int Int
    | GotTimezone Effect.Time.Zone
    | LoginFormMsg Evergreen.V218.LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Evergreen.V218.Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Evergreen.V218.Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Evergreen.V218.Route.Route
    | SelectedFilesToAttach ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | NewChannelFormChanged (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) NewChannelForm
    | PressedSubmitNewChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) NewChannelForm
    | MouseEnteredChannelName (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRoute
    | MouseExitedChannelName (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRoute
    | MouseEnteredDiscordChannelName (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRoute
    | MouseExitedDiscordChannelName (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRoute
    | EditChannelFormChanged (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) EditChannelForm
    | PressedResetEditChannelChanges (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId)
    | PressedSubmitEditChannelChanges (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) EditChannelForm
    | PressedDeleteChannel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId)
    | PressedCreateInviteLink (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId)
    | FrontendNoOp
    | PressedCopyText String
    | PressedCreateGuild
    | NewGuildFormChanged NewGuildForm
    | PressedSubmitNewGuild NewGuildForm
    | PressedCancelNewGuild
    | DebouncedTyping
    | GotPingUserPosition Effect.Browser.Dom.HtmlId (Result Effect.Browser.Dom.Error Evergreen.V218.MessageInput.MentionUserDropdown)
    | SetFocus
    | RemoveFocus
    | KeyDown String
    | MessageMenu_PressedShowReactionEmojiSelector Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels)
    | MessageMenu_PressedReactionEmoji Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | MessageMenu_PressedEditMessage Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | EmojiSelectorMsg Evergreen.V218.Emoji.Msg
    | MessageMenu_PressedReply Evergreen.V218.Id.ThreadRouteWithMessage
    | MessageMenu_PressedOpenThread (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    | PressedCloseReplyTo ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    | VisibilityChanged Effect.Browser.Events.Visibility
    | CheckedNotificationPermission Evergreen.V218.Ports.NotificationPermission
    | CheckedPwaStatus Evergreen.V218.Ports.PwaStatus
    | TouchStart (Maybe ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRouteWithMessage, Bool )) Effect.Time.Posix (Evergreen.V218.NonemptyDict.NonemptyDict Int Evergreen.V218.Touch.Touch)
    | TouchMoved Effect.Time.Posix (Evergreen.V218.NonemptyDict.NonemptyDict Int Evergreen.V218.Touch.Touch)
    | TouchEnd Effect.Time.Posix
    | TouchCancel Effect.Time.Posix
    | ChannelSidebarAnimated Duration.Duration
    | MessageMenuAnimated Duration.Duration
    | SetScrollToBottom
    | PressedChannelHeaderBackButton
    | PressedShowMembers
    | UserScrolled Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRoute ScrollPosition
    | PressedBody
    | MessageMenu_PressedDeleteMessage Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage
    | MessageMenu_PressedAddCustomEmojisToUser (Evergreen.V218.NonemptySet.NonemptySet (Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId))
    | ScrolledToMessage
    | MessageMenu_PressedClose
    | MessageMenu_PressedContainer
    | PressedCancelMessageEdit ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
    | CheckMessageAltPress Effect.Time.Posix Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Bool
    | PressedShowUserOption
    | PressedCloseUserOptions
    | TwoFactorMsg Evergreen.V218.TwoFactorAuthentication.Msg
    | AiChatMsg Evergreen.V218.AiChat.Msg
    | GoMsg Evergreen.V218.Go.Msg
    | UserNameEditableMsg (Evergreen.V218.Editable.Msg Evergreen.V218.PersonName.PersonName)
    | ProfilePictureEditorMsg Evergreen.V218.ImageEditor.Msg
    | OneFrameAfterDragEnd
    | GotFileHashName ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse)
    | PressedDeleteAttachedFile ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId)
    | PressedViewAttachedFileInfo ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId)
    | PressedToggleAttachedFileSpoiler
        ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
        { fileId : Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_PressedDeleteAttachedFile ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId)
    | EditMessage_PressedViewAttachedFileInfo ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId)
    | EditMessage_PressedToggleAttachedFileSpoiler
        ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute )
        { fileId : Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId
        , removeSpoiler : Bool
        }
    | EditMessage_SelectedFilesToAttach ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) Effect.File.File (List Effect.File.File)
    | EditMessage_GotFileHashName ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) (Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse)
    | FileUploadProgress ( Evergreen.V218.Id.AnyGuildOrDmId, Evergreen.V218.Id.ThreadRoute ) (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Effect.Http.Progress
    | MessageViewMsg Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRouteWithMessage Evergreen.V218.MessageView.MessageViewMsg
    | GotRegisterPushSubscription (Result String Evergreen.V218.UserSession.SubscribeData)
    | SelectedNotificationMode Evergreen.V218.UserSession.NotificationMode
    | PressedGuildNotificationLevel (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) Evergreen.V218.User.NotificationLevel
    | PressedDiscordGuildNotificationLevel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) Evergreen.V218.User.NotificationLevel
    | GotScrollbarWidth Int
    | PressedCloseImageInfo
    | PressedMemberListBack
    | GotUserAgent Evergreen.V218.UserAgent.UserAgent
    | PageHasFocusChanged Bool
    | GotServiceWorkerMessage String
    | VisualViewportResized Float
    | TextEditorMsg Evergreen.V218.TextEditor.Msg
    | PressedDiscordAcknowledgment Bool
    | PressedLinkDiscordUser
    | PressedReloadDiscordUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | PressedUnlinkDiscordUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
    | PressedDiscordGuildMemberLabel
        { currentUserId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId
        , otherUserId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId
        }
    | TypedDiscordLinkBookmarklet
    | GotVersionNumber (Result Effect.Http.Error Int)
    | PressedCloseExternalLinkWarning
    | PressedAddDomainToWhitelist Bool
    | TypedDomainWhitelist String
    | PressedSaveDomainWhitelist
    | PressedResetDomainWhitelist
    | PressedContinueToSite
    | EditMessage_MessageInputMsg Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRoute Evergreen.V218.MessageInput.Msg
    | MessageInputMsg Evergreen.V218.Id.AnyGuildOrDmId Evergreen.V218.Id.ThreadRoute Evergreen.V218.MessageInput.Msg
    | GotEmojiData (Result Effect.Http.Error Evergreen.V218.Emoji.CachedEmojiData)
    | GotEditMessageTextInputPositionForEmojiSelector (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Element)
    | EnableToFrontendLogging
    | TextSelectionChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V218.Range.Range, Evergreen.V218.Range.SelectionDirection ) )
    | DomFocusChanged ( Maybe Effect.Browser.Dom.HtmlId, Maybe ( Evergreen.V218.Range.Range, Evergreen.V218.Range.SelectionDirection ) )
    | PageUpGotViewport (Result Effect.Browser.Dom.Error Effect.Browser.Dom.Viewport)
    | GotVoiceChatSignalFromJs (Result String Evergreen.V218.VoiceChat.FromJs)
    | GotVoiceChatRecording Bytes.Bytes
    | VoiceChatMsg Evergreen.V218.VoiceChat.Msg
    | PressedChannelHeaderTab Evergreen.V218.Route.DmChannelHeaderTab
    | FileDragEnter
    | FileDragLeave
    | FileDropped (List Effect.File.File)


type InitialLoadRequest
    = InitialLoadRequested_Guild (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRoute
    | InitialLoadRequested_Dm Evergreen.V218.DmChannel.DmChannelId Evergreen.V218.Id.ThreadRoute
    | InitialLoadRequested_Discord Evergreen.V218.Id.DiscordGuildOrDmId Evergreen.V218.Id.ThreadRoute
    | InitialLoadRequested_Admin (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Pagination.PageId))
    | InitialLoadRequested_None


type ToBackend
    = CheckLoginRequest InitialLoadRequest
    | LoginWithTokenRequest InitialLoadRequest Int Evergreen.V218.UserAgent.UserAgent
    | LoginWithTwoFactorRequest InitialLoadRequest Int Evergreen.V218.UserAgent.UserAgent
    | GetLoginTokenRequest (Evergreen.V218.Untrusted.Untrusted Evergreen.V218.EmailAddress.EmailAddress)
    | AdminToBackend Evergreen.V218.Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest Evergreen.V218.Local.ChangeId LocalChange
    | TwoFactorToBackend Evergreen.V218.TwoFactorAuthentication.ToBackend
    | JoinGuildByInviteRequest (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)
    | FinishUserCreationRequest InitialLoadRequest Evergreen.V218.PersonName.PersonName Evergreen.V218.UserAgent.UserAgent
    | AiChatToBackend Evergreen.V218.AiChat.ToBackend
    | ReloadDataRequest InitialLoadRequest
    | LinkSlackOAuthCode Evergreen.V218.Slack.OAuthCode Evergreen.V218.SessionIdHash.SessionIdHash
    | LinkDiscordRequest Evergreen.V218.Discord.UserAuth
    | ProfilePictureEditorToBackend Evergreen.V218.ImageEditor.ToBackend
    | AdminDataRequest (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Pagination.PageId))


type MessageFromGuildOrDm
    = MessageFromGuildOrDm_Guild (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
    | MessageFromGuildOrDm_Dm (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId)


type BackendMsg
    = SentLoginEmail Effect.Time.Posix Evergreen.V218.EmailAddress.EmailAddress (Result Evergreen.V218.Postmark.SendEmailError ())
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserDisconnectedWithTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId Effect.Time.Posix
    | BackendGotTime Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | SentLogErrorEmail Effect.Time.Posix Evergreen.V218.EmailAddress.EmailAddress (Result Evergreen.V218.Postmark.SendEmailError ())
    | DiscordUserWebsocketMsg (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Evergreen.V218.Discord.Msg
    | SentDiscordGuildMessage Effect.Time.Posix Evergreen.V218.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMaybeMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Result Evergreen.V218.Discord.HttpError Evergreen.V218.Discord.Message)
    | SentDiscordDmMessage Effect.Time.Posix Evergreen.V218.Local.ChangeId Effect.Lamdera.SessionId Effect.Lamdera.ClientId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Result Evergreen.V218.Discord.HttpError Evergreen.V218.Discord.Message)
    | DeletedDiscordGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Result Evergreen.V218.Discord.HttpError ())
    | DeletedDiscordDmMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Result Evergreen.V218.Discord.HttpError ())
    | EditedDiscordGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Result Evergreen.V218.Discord.HttpError ())
    | EditedDiscordDmMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Result Evergreen.V218.Discord.HttpError ())
    | DiscordAddedReactionToGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji (Result Evergreen.V218.Discord.HttpError ())
    | DiscordAddedReactionToDmMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji (Result Evergreen.V218.Discord.HttpError ())
    | DiscordRemovedReactionToGuildMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji (Result Evergreen.V218.Discord.HttpError ())
    | DiscordRemovedReactionToDmMessage Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) Evergreen.V218.Emoji.EmojiOrCustomEmoji (Result Evergreen.V218.Discord.HttpError ())
    | DiscordTypingIndicatorSent
    | AiChatBackendMsg Evergreen.V218.AiChat.BackendMsg
    | GotDiscordUserAvatars (Result Evergreen.V218.Discord.HttpError (List ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId, Maybe Evergreen.V218.FileStatus.UploadResponse ))) Effect.Time.Posix
    | SentNotification Effect.Lamdera.SessionId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Effect.Time.Posix (Result Effect.Http.Error ())
    | GotVapidKeys (Result Effect.Http.Error String)
    | GotSlackChannels
        Effect.Time.Posix
        (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
        (Result
            Effect.Http.Error
            { currentUser : Evergreen.V218.Slack.CurrentUser
            , team : Evergreen.V218.Slack.Team
            , users : List Evergreen.V218.Slack.User
            , channels : List ( Evergreen.V218.Slack.Channel, List Evergreen.V218.Slack.Message )
            }
        )
    | GotSlackOAuth Effect.Time.Posix (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Result Effect.Http.Error Evergreen.V218.Slack.TokenResponse)
    | LinkDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Discord.UserAuth (Result Evergreen.V218.Discord.HttpError Evergreen.V218.Discord.User)
    | ReloadDiscordUserStep1 Effect.Time.Posix Effect.Lamdera.ClientId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Result Evergreen.V218.Discord.HttpError Evergreen.V218.Discord.User)
    | HandleReadyDataStep2
        Effect.Time.Posix
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
        (Result
            Evergreen.V218.Discord.HttpError
            ( List
                { dmChannelId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId
                , members : List (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
                }
            , List
                ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId
                , { guild : Evergreen.V218.Discord.GatewayGuild
                  , channels : List Evergreen.V218.Discord.Channel
                  , icon : Maybe Evergreen.V218.FileStatus.UploadResponse
                  }
                )
            )
        )
    | WebsocketCreatedHandleForUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Effect.Websocket.Connection
    | WebsocketClosedByBackendForUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) Bool
    | WebsocketSentDataForUser (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Result Effect.Websocket.SendError ())
    | DiscordMessageCreate_AttachmentsUploaded Evergreen.V218.Discord.Message (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.AttachmentId, Evergreen.V218.FileStatus.UploadResponse )))
    | DiscordMessageUpdate_AttachmentsUploaded Evergreen.V218.Discord.UserMessageUpdate (List.Nonempty.Nonempty (Result Effect.Http.Error ( Evergreen.V218.Discord.Id Evergreen.V218.Discord.AttachmentId, Evergreen.V218.FileStatus.UploadResponse )))
    | ReloadedDiscordGuildChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (List (Result Effect.Http.Error ( Evergreen.V218.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V218.FileStatus.UploadResponse )))
    | ReloadedDiscordDmChannel (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (List (Result Effect.Http.Error ( Evergreen.V218.DiscordAttachmentId.DiscordAttachmentId, Evergreen.V218.FileStatus.UploadResponse )))
    | ExportBackendStep
    | ScheduledExportBackendStep Effect.Time.Posix
    | GotDiscordGuildChannelMessages Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) (Result Evergreen.V218.Discord.HttpError (List Evergreen.V218.Discord.Message))
    | GotDiscordDmChannelMessages Effect.Time.Posix (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Result Evergreen.V218.Discord.HttpError (List Evergreen.V218.Discord.Message))
    | GotTimeForFailedToParseDiscordWebsocket (Maybe String) String Effect.Time.Posix
    | GotGuildMessageEmbed (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V218.Embed.EmbedData )
    | GotDmMessageEmbed Evergreen.V218.DmChannel.DmChannelId Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V218.Embed.EmbedData )
    | DiscordGotGuildMessageEmbed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) Evergreen.V218.Id.ThreadRouteWithMessage ( Url.Url, Result Effect.Http.Error Evergreen.V218.Embed.EmbedData )
    | DiscordGotDmMessageEmbed (Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) ( Url.Url, Result Effect.Http.Error Evergreen.V218.Embed.EmbedData )
    | DiscordGotDataForJoinedOrCreatedGuild
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
        (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId)
        Effect.Time.Posix
        (Result
            Evergreen.V218.Discord.HttpError
            { guild : Evergreen.V218.Discord.GatewayGuild
            , channels : List Evergreen.V218.Discord.Channel
            , icon : Maybe Evergreen.V218.FileStatus.UploadResponse
            }
        )
    | JoinedDiscordThread (Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId) (Result Evergreen.V218.Discord.HttpError ()) Effect.Time.Posix
    | ToBackendCompleted
        Evergreen.V218.ToBackendLog.ToBackendLog
        (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
        { startTime : Effect.Time.Posix
        , endTime : Effect.Time.Posix
        }
    | GotDiscordReadyDataStickers (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (List ( Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId, Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageStickers MessageFromGuildOrDm (List ( Evergreen.V218.Id.Id Evergreen.V218.Id.StickerId, Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordReadyDataCustomEmojis (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (List ( Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse )) Effect.Time.Posix
    | GotDiscordMessageCustomEmojis MessageFromGuildOrDm (List ( Evergreen.V218.Id.Id Evergreen.V218.Id.CustomEmojiId, Result Effect.Http.Error Evergreen.V218.FileStatus.UploadResponse )) Effect.Time.Posix
    | HourlyUpdate Effect.Time.Posix
    | GotDiscordStandardStickerPacks Effect.Time.Posix (Result Evergreen.V218.Discord.HttpError (List Evergreen.V218.Discord.StickerPack))
    | ScheduledExportUploadResult Effect.Time.Posix (Result Effect.Http.Error ())
    | RegeneratedServerSecret Effect.Time.Posix Evergreen.V218.Local.ChangeId Effect.Lamdera.ClientId (Result Effect.Http.Error (Evergreen.V218.SecretId.SecretId Evergreen.V218.SecretId.ServerSecret))
